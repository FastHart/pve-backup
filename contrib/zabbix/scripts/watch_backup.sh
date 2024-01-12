#! /usr/bin/perl
#
# Last edited 04.07.2014 by VPS 
#
# Скрипт читает файл с логом, проверяет на наличие в нем ключевых фраз, перечисленных в конфиг-файле
# Если ключевая фараза найдена, то строка, содержащая ее передается в в zabbix чеез zabbix_sender
# В начале передаваемой строки добавляется слово PROBLEM: (это для триггера в заббикс)
# Если ключевая фраза не найдена, то в заббикс передатся "ОК"
#
#
$debug=0;

$log_file="/var/log/00_pve-backup.log"; # лог-файл который мониторим

$errors_file="/etc/zabbix/scripts/watch_backup_errors"; # список ключевых фарз которые ищем в логе

$zabbix_sender = "/usr/bin/zabbix_sender";
$zabbix_conf = "/etc/zabbix/zabbix_agentd.conf";
$zabbix_key = "watch_backup"; # Ключ в заббиксе


die "cant open $errors_file" if (!-e $errors_file);
die "cant open $log_file" if (!-e $log_file);
die "zabbix_sender ($zabbix_sender) not found" if (!-e $zabbix_sender);
die "zabbix config ($zabbix_conf) not found" if (!-e $zabbix_conf);

# Читаем файл с ошибками в массив
open (ERRORS_FILE,$errors_file) || die "Sorry, I couldnt open $errors_file";
while (<ERRORS_FILE>)
    {
    chomp;
    next if ( (length == 0) ||  (m/^\#/)  ); # если строка пустая или начинается с символа комментарии то далее
    push (@common_errors,$_);
    }
close ERRORS_FILE;

# Читаем логфайл и каждую строку сверяем с массивом
open (LOG_FILE,$log_file)  || die "Sorry, I couldnt open $log_file"; 

$errors_cnt=0;

while (<LOG_FILE>)
    {
    chomp;
    $line = $_;
    foreach (@common_errors){ if ($line =~ m/.*$_.*/ ) {$founded_error_line=$line; $errors_cnt++;}	}
#	<stdin>;
    }
close LOG_FILE;

if ($founded_error_line){system "$zabbix_sender -c $zabbix_conf -k $zabbix_key -o \"PROBLEM: $founded_error_line\"";}
else {system "$zabbix_sender -c $zabbix_conf -k $zabbix_key -o \"OK\"";}

exit if ($debug == 0);
# Выводим результаты на stdin если включен дебаг
if ($founded_error_line){ print "$founded_error_line\n";}
  else {print "OK\n";}


