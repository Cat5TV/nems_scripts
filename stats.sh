#!/usr/bin/php
<?php
// # This is simple, anonymous stats just so Robbie knows a bit about how many systems are using NEMS.
// # This will also help me understand limitations of various platforms (ie, how many hosts can a Pi 3 handle?).
// # Please do not deactivate this unless you absolutely have to.
// # Again, it's completely anonymous, and nothing private is revealed.

if (!file_exists('/var/log/nems/hw_model')) {
  // Just in case this is the first boot and running at startup, let's hang tight for 30 seconds to let the data generate
  sleep(30);
}

if (file_exists('/var/log/nems/hw_model')) { // Don't run this until system is ready to report true stats

  // Get the platform of your NEMS server
  $platform = trim(shell_exec('/usr/local/bin/nems-info platform'));

  // Get the number of configured hosts
  $hostdata = file('/etc/nagios3/Default_collector/hosts.cfg');
  $hosts = 0;
  if (is_array($hostdata)) foreach ($hostdata as $line) {
    if (strstr($line, 'define host')) $hosts++;
  }

  // Get the number of configured services
  $servicedata = file('/etc/nagios3/Default_collector/services.cfg');
  $services = 0;
  if (is_array($servicedata)) foreach ($servicedata as $line) {
    if (strstr($line, 'define service')) $services++;
  }

  // Get the size of your storage media
  $disksize = disk_total_space('/');
  $diskfree = disk_free_space('/');

  // Determine system uptime
  $str   = @file_get_contents('/proc/uptime');
  $num   = floatval($str);
  $secs  = floor(fmod($num, 60)); $num = intdiv($num, 60);
  $mins  = $num % 60;      $num = intdiv($num, 60);
  $hours = $num % 24;      $num = intdiv($num, 24);
  $days  = $num;

  // Put it together to send to the server
  $data = array(
    'hwid'=>trim(shell_exec('/usr/local/bin/nems-info hwid')),
    'platform'=>$platform,
    'uptime_days'=>$days,
    'uptime_hours'=>$hours,
    'uptime_mins'=>$mins,
    'uptime_secs'=>$secs,
    'nemsver'=>trim(shell_exec('/usr/local/bin/nems-info nemsver')),
    'hosts'=>$hosts,
    'services'=>$services,
    'disksize'=>$disksize,
    'diskfree'=>$diskfree,
    'loadaverage'=>trim(shell_exec('/usr/local/bin/nems-info loadaverage')),
    'temperature'=>trim(shell_exec('/usr/local/bin/nems-info temperature')),
    'timezone'=>date('T'),
  );

  // Load existing NEMS Stats API Key, if it exists
  $settings = @file('/usr/local/share/nems/nems.conf');
  if (is_array($settings) && count($settings) > 0) {
    foreach ($settings as $line) {
      if (substr($line,0,6) == 'apikey') {
        $data['apikey'] = substr($line,7);
      }
    }
  }

  $ch = curl_init('https://nemslinux.com/api/stats/');
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
//  $response = curl_exec($ch);
  $retry = 0;
  $newkey = '';
  while((curl_errno($ch) == 28 || $newkey == '') && $retry < 1440){ // error 28 is timeout - retry every 5 seconds for 1440 tries (2 hours). Will also retry if an apikey is not sent by the server.
    $response = curl_exec($ch);
    sleep(5);
    $newkey = filter_var($response,FILTER_SANITIZE_STRING);
    if (strlen($newkey) > 0) break;
    $retry++;
  }

  curl_close($ch);
  if (!isset($data['apikey'])) {
    $data['apikey'] = $newkey; // no API Key in settings, use the new one
    file_put_contents('/usr/local/share/nems/nems.conf','apikey=' . $newkey . PHP_EOL, FILE_APPEND);
  }

}
?>