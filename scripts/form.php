<html>
  <head>
    <title>Configure `birdnet.conf`</title>
    <style>
* {
  font-family: 'Arial', 'Gill Sans', 'Gill Sans MT',
  ' Calibri', 'Trebuchet MS', 'sans-serif';
}

h1,h2,h3 {
  text-align:center;
}
  input {
    font-size:large;
  }
    </style>
  </head>
  <h1>Configure BirdNET-Pi</h1>
  <body style="background-color: rgb(119, 196, 135);">
    <form style="text-align:center;" action="write_config.php" method="POST">
<?php 
  if (file_exists('/home/pi/BirdNET-Pi/thisrun.txt')) {
    $config = parse_ini_file('/home/pi/BirdNET-Pi/thisrun.txt');
  } elseif (file_exists('/home/pi/BirdNET-Pi/firstrun.ini')) {
    $config = parse_ini_file('/home/pi/BirdNET-Pi/firstrun.ini');
  } ?>
      <h3>Required</h3>
      <input name="field1" type="text" value="LATITUDE"/>
      <input name="field2" type="text" value="<?php print($config['LATITUDE']);?>" /><br>
      <input name="field3" type="text" value="LONGITUDE" />
      <input name="field4" type="text" value="<?php print($config['LONGITUDE']);?>" /><br>
      <input name="field5" type="text" value="CADDY_PWD" />
      <input name="field6" type="text" value="<?php print($config['CADDY_PWD']);?>" /><br>
      <input name="field7" type="text" value="DB_PWD" />
      <input name="field8" type="text" value="<?php print($config['DB_PWD']);?>" /><br>
      <input name="field9" type="text" value="ICE_PWD" />
      <input name="field10" type="text" value="<?php print($config['ICE_PWD']);?>" /><br>
    </form>
    <form style="text-align:center;" action="write_config.php" method="POST">
      <h3>Optional Services</h3>
      <input name="field11" type="text" value="BIRDWEATHER_ID" />
      <input name="field12" type="text" value="<?php print($config['BIRDWEATHER_ID']);?>" /><br>
      <input name="field13" type="text" value="PUSHED_APP_KEY" />
      <input name="field14" type="text" value="<?php print($config['PUSHED_APP_KEY']);?>" /><br>
      <input name="field15" type="text" value="PUSHED_APP_SECRET" />
      <input name="field16" type="text" value="<?php print($config['PUSHED_APP_SECRET']);?>" /><br>
    </form>
    <form style="text-align:center;" action="write_config.php" method="POST">
      <h3>Custom URLs</h3>
      <input name="field17" type="text" value="BIRDNETPI_URL" />
      <input name="field18" type="text" value="<?php print($config['BIRDNETPI_URL']);?>" /><br>
      <input name="field19" type="text" value="EXTRACTIONLOG_URL" />
      <input name="field20" type="text" value="<?php print($config['EXTRACTIONLOG_URL']);?>" /><br>
      <input name="field21" type="text" value="BIRDNETLOG_URL" />
      <input name="field22" type="text" value="<?php print($config['BIRDNETLOG_URL']);?>" /><br>
    </form>
    <form style="text-align:center;" action="write_config.php" method="POST">
      <h3>Default Services</h3>
      <input name="field23" type="text" value="INSTALL_NOMACHINE" />
      <input name="field24" type="text" value="<?php print($config['INSTALL_NOMACHINE']);?>" /><br>
      <input name="field25" type="text" value="DO_EXTRACTIONS" />
      <input name="field26" type="text" value="<?php print($config['DO_EXTRACTIONS']);?>" /><br>
      <input name="field27" type="text" value="DO_RECORDING" />
      <input name="field28" type="text" value="<?php print($config['DO_RECORDING']);?>" /><br>
    </form>
    <form style="text-align:center;" action="write_config.php" method="POST">
      <h3>Advanced Configuration</h3>
      <input name="field29" type="text" value="REC_CARD" />
      <input name="field30" type="text" value="<?php print($config['REC_CARD']);?>" /><br>
      <input name="field31" type="text" value="OVERLAP" />
      <input name="field32" type="text" value="<?php print($config['OVERLAP']);?>" /><br>
      <input name="field33" type="text" value="CONFIDENCE" />
      <input name="field34" type="text" value="<?php print($config['CONFIDENCE']);?>" /><br>
      <input name="field35" type="text" value="SENSITIVITY" />
      <input name="field36" type="text" value="<?php print($config['SENSITIVITY']);?>" /><br>
      <input name="field37" type="text" value="CHANNELS" />
      <input name="field38" type="text" value="<?php print($config['CHANNELS']);?>" /><br>
      <input name="field39" type="text" value="RECORDING_LENGTH" />
      <input name="field40" type="text" value="<?php print($config['RECORDING_LENGTH']);?>" /><br>
      <input name="field41" type="text" value="EXTRACTION_LENGTH" />
      <input name="field42" type="text" value="<?php print($config['EXTRACTION_LENGTH']);?>" /><br>
    </form>
    <a style="font-weight:bold;color:black;" href='birdnet.conf'>View Current Config</a>
  </body>