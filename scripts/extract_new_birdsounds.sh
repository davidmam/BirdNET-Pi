#!/usr/bin/env bash
# Exit when any command fails
#set -x
set -e
# Keep track of the last executed command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
## Echo an error message before exiting
#trap 'echo "\"${last_command}\" command exited with code $?."' EXIT
# Remove temporary file
trap 'rm -f $TMPFILE' EXIT
source /etc/birdnet/birdnet.conf
[ -z ${RECORDING_LENGTH} ] && RECORDING_LENGTH=15

# Set Variables
TMPFILE=$(mktemp)
ANALYZED=${RECS_DIR}/*/*Analyzed
# SCAN_DIRS are all directories marked "Analyzed"
SCAN_DIRS=($(find ${ANALYZED} -type d | sort ))

for h in "${SCAN_DIRS[@]}";do
  # The TMPFILE is created from each .csv file BirdNET creates
  # within each "Analyzed" directory
  #  Field 1: Start (s)
  #  Field 2: End (s)
  #  Field 3: Scientific name
  #  Field 4: Common name
  #  Field 5: Confidence

  # Removes old directories
  if echo "${h}" | grep $(date --date="yesterday" "+%A") &> /dev/null;then
    echo "Removing old directories"
    rm -drf "${h}"
    rm -drf "$(echo ${h} | cut -d'-' -f1-3)"
    continue
  fi

  # Iterates over each "Analyzed" directory
  for i in $(find ${h} -name '*csv' | sort );do 
    # Iterates over each '.csv' file found in each "Analyzed" directory
    # to create the TMPFILE
    echo "${i}" | cut -d'/' -f7 >> ${TMPFILE}
    sort -k1n -t\; "${i}" | awk '!/Start/{print}' >> ${TMPFILE}
  done

  # The extraction reads each line of the TMPFILE and sets the variables ffmpeg
  # will use.
  while read -r line;do
    DATE="$(echo "${line}" \
      | awk -F- '/birdnet/{print $1"-"$2"-"$3}')"
    if [ ! -z ${DATE} ];then
      OLDFILE="$(echo "${line}" | awk -F. '/birdnet/{print $1"."$2}')" ; continue
    fi

    if [ -z ${DATE} ];then
      DATE=$(date "+%F")
    fi
    START="$(echo "${line}" | awk -F\; '!/birdnet/{print $1}')" 
    END="$(echo "${line}" | awk -F\; '!/birdnet/{print $2}')" 
    COMMON_NAME=""$(echo ${line} \
            | awk -F\; '!/birdnet/{print $4}'|tr -d "'")""
    SCIENTIFIC_NAME=""$(echo ${line} \
            | awk -F\; '!/birdnet/{print $3}')""
    CONFIDENCE=""$(echo ${line} \
	    | awk -F\; '{print $5}' \
	    | cut -d'.' -f2)""
    CONFIDENCE_SCORE="${CONFIDENCE:0:2}%"
    NEWFILE="${COMMON_NAME// /_}-${CONFIDENCE_SCORE}-${OLDFILE}"
    NEWSPECIES_BYDATE="${EXTRACTED}/By_Date/${DATE}/${COMMON_NAME// /_}"
    NEWSPECIES_BY_COMMON="${EXTRACTED}/By_Common_Name/${COMMON_NAME// /_}"
    NEWSPECIES_BY_SCIENCE="${EXTRACTED}/By_Scientific_Name/${SCIENTIFIC_NAME// /_}"

    # If the extracted file already exists, move on
    if [[ -f "${NEWSPECIES_BYDATE}/${NEWFILE}" ]];then
      echo "Extraction exists. Moving on"
      continue
    fi


    # Before extracting the "Selection," the script checks to be sure the
    # original WAVE file still exists.
    [[ -f "${h}/${OLDFILE}" ]] || continue

    # If a directory does not already exist for the species (by date),
    # it is created
    [[ -d "${NEWSPECIES_BYDATE}" ]] || mkdir -p "${NEWSPECIES_BYDATE}"


    # If a directory does not already exist for the species (by-species),
    # it is created.
    [[ -d "${NEWSPECIES_BY_COMMON}" ]] || mkdir -p "${NEWSPECIES_BY_COMMON}"

    # If a directory does not already exist for the species (by-species),
    # it is created.
    [[ -d "${NEWSPECIES_BY_SCIENCE}" ]] || mkdir -p "${NEWSPECIES_BY_SCIENCE}"


    # If there are already 20 extracted entries for a given species
    # for today, remove the oldest file and create the new one.
   # if [[ "$(find ${NEWSPECIES_BYDATE} | wc -l)" -ge 20 ]];then
   #   echo "20 ${SPECIES}s, already! Removing the oldest by-date and making a new one"
   #   cd ${NEWSPECIES_BYDATE} || exit 1
   #   ls -1t . | tail -n +20 | xargs -r rm -vv
   # fi   

    echo "Extracting audio . . . "
    # If the above tests have passed, then the extraction happens.
    # After creating the extracted files by-date, and a directory tree 
    # structured by-species, symbolic links are made to populate the new 
    # directory.

    # This section sets the SPACER that will be used to pad the audio clip with
    # context. If EXTRACTION_LENGTH is 10, for instance, 3 seconds are removed
    # from that value and divided by 2, so that the 3 seconds of the call are
    # within 3.5 seconds of audio context before and after.
    [ -z ${EXTRACTION_LENGTH} ] && EXTRACTION_LENGTH=6
    SPACER=$(echo "scale=1;(${EXTRACTION_LENGTH} - 3 )/2" |bc -l) 
    START=$(echo "scale=1;${START} - ${SPACER}"|bc -l)
    END=$(echo "scale=1;${END} + ${SPACER}"|bc -l)
    
    # If the SPACER would have the START value less that 0, start at the
    # beginning of the audio file. If the SPACER would make the END value
    # exceed the end of the audio file, end the extraction at the end of the
    # audio file.
    if (( $(echo "${START} < 1" | bc -l) ));then START=0;fi
    if (( $(echo "${END} > ${RECORDING_LENGTH}" | bc -l) ));then END=${RECORDING_LENGTH};fi

    ffmpeg -hide_banner -loglevel error -nostdin -i "${h}/${OLDFILE}" \
      -acodec copy -ss "${START}" -to "${END}"\
        "${NEWSPECIES_BYDATE}/${NEWFILE}"

    # Create spectrogram for extraction
    sox "${NEWSPECIES_BYDATE}/${NEWFILE}" -n remix 1 rate 24k spectrogram \
      -t "${COMMON_NAME}" \
      -c "${NEWSPECIES_BYDATE}/${NEWFILE}" \
      -o "${NEWSPECIES_BYDATE}/${NEWFILE}.png"
    
    # Remove the oldest symbolic links that would make the directory have more
    # than 20 entries.
    if [[ "$(find ${NEWSPECIES_BY_COMMON} | wc -l)" -ge 40 ]];then
      echo "20 ${SPECIES}s, already! Removing the oldest by-species and making a new one"
      cd ${NEWSPECIES_BY_COMMON} || exit 1
      ls -1t . | tail -n +40 | xargs -r rm -vv
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}"\
        "${NEWSPECIES_BY_COMMON}/${NEWFILE}"
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}.png"\
        "${NEWSPECIES_BY_COMMON}/${NEWFILE}.png"
      echo "Success! New extraction for ${COMMON_NAME}"
    else
    # Make symbolic link of the extraction to add to By_Common_Name
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}"\
        "${NEWSPECIES_BY_COMMON}/${NEWFILE}"
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}.png"\
        "${NEWSPECIES_BY_COMMON}/${NEWFILE}.png"
    fi   

    # Remove the oldest symbolic links that would made the directory have more
    # than 20 entries.
    if [[ "$(find ${NEWSPECIES_BY_SCIENCE} | wc -l)" -ge 40 ]];then
      echo "20 ${SPECIES}s, already! Removing the oldest by-species and making a new one"
      cd ${NEWSPECIES_BY_SCIENCE} || exit 1
      ls -1t . | tail -n +40 | xargs -r rm -vv
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}"\
        "${NEWSPECIES_BY_SCIENCE}/${NEWFILE}"
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}.png"\
        "${NEWSPECIES_BY_SCIENCE}/${NEWFILE}.png"
      echo "Success! New extraction for ${COMMON_NAME}"
    else
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}"\
        "${NEWSPECIES_BY_SCIENCE}/${NEWFILE}"
      ln -fs "${NEWSPECIES_BYDATE}/${NEWFILE}.png"\
        "${NEWSPECIES_BY_SCIENCE}/${NEWFILE}.png"
    fi   


    # Finally, 'a' is incremented by one to allow multiple extractions per
    # species per minute.
    #a=$((a + 1))

  done < "${TMPFILE}"
  
  echo -e "\n\n\nFINISHED!!! Processed extractions for ${h:19}"
  # Once each line of the TMPFILE has been processed, the TMPFILE is emptied
  # for the next iteration of the for loop.
  >"${TMPFILE}"

  # Rename files that have been processed so that they are not processed on the
  # next extraction.
  [[ -d "${PROCESSED}" ]] || mkdir "${PROCESSED}"
  echo "Moving processed files to ${PROCESSED}"
  mv ${h}/* ${PROCESSED} &> /dev/null || continue
done

echo "Linking Processed files to "${EXTRACTED}/Processed" web directory"
# After all audio extractions have taken place, a directory is created to house
# the original WAVE and .txt files used for this extraction processs.
if [[ ! -L ${EXTRACTED}/Processed ]] || [[ ! -e ${EXTRACTED}/Processed ]];then
  ln -sf ${PROCESSED} ${EXTRACTED}/Processed
fi
  


# That's all!
echo "Finished -- the extracted sections are in ${EXTRACTED}"
