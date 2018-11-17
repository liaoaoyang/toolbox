#!/usr/bin/expect
# usage:
# chmod +x expect_ssh_sample.exp
# expect_ssh_sample.exp 123456
#trap sigwinch spawned
trap {
	set rows [stty rows]
	set cols [stty columns]
	stty rows $rows columns $cols < $spawn_out(slave,name)
} WINCH

set timeout 30 
set username "your_user_name"
set host "your.server.com"
set passwd "your_ssh_password"
set rsa_static_passwd "your_rsa_token_static_password"
set passcode [lindex $argv 0]
spawn ssh -o ServerAliveInterval=60 -l $username $host
expect "password:" { send "$passwd\n" } 
expect "PASSCODE:" { send "$rsa_static_passwd$passcode\n" }
interact 
