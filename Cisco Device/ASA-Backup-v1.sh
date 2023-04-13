#!/usr/bin/expect
###
 # @Descripttion: This program is the property of the Digital China project
 # @version: 2.6
 # @Author: Zhang Boqian (Daniel)
 # @Date: 2023-02-13 09:49:23
 # @LastEditors: Daniel
 # @LastEditTime: 2023-03-06 11:09:27
 # V2.0版本升级内容
 # 1 可以从hkasa.txt读取设备清单，用户名，密码，特权密码 (可根据平台区域进行备份部署）
 # 2 记录登录失败的设备日志，无法登录的设备记录在backup-error.log文件
 # 3 解决设备登录失败无法跳过卡死问题，新代码跳过故障设备并继续执行备份其他设备
 # 4 设备日期表达方式变量改进
 # 5 遍历日志文件目录并比对设备登陆清单是否存在备份生成文件，并记录错误日志
 # 6 解决登录设备卡在用户名，无法直接输入密码登录设备的问题
 # 7 调整日志生成文件的命名规则
 # 8 在v1基础上增加了一倍的程序代码
 # V2.1版
 # 1 增加设备分组，并使用分组定义存储日志目录
 # V2.2版
 # 1 判断日志目录是否存在，如果不存在创建目录
 # V2.3版
 # 1 备份失败记录日志优化，更易于识别备份失败设备
 # 2 设备状态检查，日志检查并记录在备份文件中
 # V2.4版
 # 1 备份设备后增加设备状态检查命令并将结果记录日志
 # 2 程序增加延时减轻设备读取数据压力
 # V2.5版
 # 1 增加了统计成功和失败设备数量的部分，并在备份结束后将结果写入统计数据文件
 # 2 调整了登录超时时间，5秒未能登录成功将判定为备份失败设备
 # V2.6版
 # 1 修改expect语句判断时间，登录用户名密码的超时5秒，登录成功后条件判断程序每个判断由5秒调整为1秒
 # 2 增加terminal len 0屏显失败后输入terminal page 0来适应部分设备，解决屏显无法收取完整配置问题
 # 2.7版
 # 1 修复登录阶段输入用户名或密码错误导致程序退出
 # 2 增加用户名、密码错误后的日志记录并参与统计结果
 # 版本变更ASA-Backup-v1
### 
set timeout 120
#Read username, password, and enable password from hkasa.txt
set fp [open "/zbq/hkasa.txt" r]
set file_data [read $fp]
close $fp
set file_lines [split $file_data "\n"]
set line1 [lindex $file_lines 0]
set fields [split $line1 " "]
set username [lindex $fields 2]
set password [lindex $fields 3]
set enablepassword [lindex $fields 4]
set aa _
set current_folder ""
#Read device names, IP addresses, and per-device credentials from hkasa.txt
set devices {}
set fp [open "/zbq/hkasa.txt" r]
while {[gets $fp line] != -1} {
    set fields [split $line " "]
    if {[string match "#*" [lindex $fields 0]]} {
        set current_folder [string range [lindex $fields 0] 1 end]
        continue
    }
    lappend devices [list [lindex $fields 0] [lindex $fields 1] [lindex $fields 2] [lindex $fields 3] [lindex $fields 4] $current_folder]
}
close $fp
set today [exec date +%Y-%m-%d]
set backup_error_file "/zbq/backup-$today-error.log"
    if {![file exists $backup_error_file]} {
    exec touch $backup_error_file
    exec chmod 644 $backup_error_file
    }
foreach device $devices {
    set device_name [lindex $device 0]
    set device_ip [lindex $device 1]
    set device_username [lindex $device 2]
    set device_password [lindex $device 3]
    set device_enablepassword [lindex $device 4]
    set device_folder [lindex $device 5]

    # Create log file directory if it doesn't exist
    set log_dir "/etc/ansible/playbook/DatacenterTOR_backup/$device_folder"
    if {![file exists $log_dir]} {
        file mkdir $log_dir
    }
    set log_file "$log_dir/$today$aa$device_ip$aa$device_name.txt"
    puts " "
    puts " "
    puts "############################################"
    puts "Logging into device: $device_name"
    puts "############################################"
    puts " "
    spawn telnet $device_ip
	log_file -noappend
    log_file -noappend $log_file
    set timeout 5
    expect {
		    -re "login:|Username:" {
		        # This device requires a username
		        send "$device_username\r"
		        expect "Password:"
		        send "$device_password\r"
				sleep 1
                expect {
                    "Authentication failed" {
                    # Telnet prompt did not appear, connection failed
                    puts "Unable to connect to device: $device_name, IP: $device_ip"
                    set fp [open $backup_error_file a]
                    puts $fp "$device_name $device_ip $today ===failed=== "
                    close $fp
                    continue
                    }
		            ">" {
		                send "en\r"
		                expect "Password:"
		                send "$device_enablepassword\r"
		                expect "#"
		            }
		            "#" {
		                # Do nothing and continue to the next command
		            }
		        }
		        send "terminal len 0\r"
				expect {
		            "ERROR: % Invalid input detected at '^' marker." {
		                send "terminal page 0\r"
		                expect "#"
		            }
		            "#" {
		                # Do nothing and continue to the next command
		            }
		        }				
		        expect -timeout 1 "#"
		        send "show inventory\r"
		        sleep 0.2
		        expect "#"
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "show inv\r"
		        expect "#"				
		        send "show ver\r"
		        expect "#"		
		        send "show inv\r"
		        expect "#"						
		        send "changeto system\r"
		        sleep 0.2
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "changeto context ctx1\r"
		        sleep 0.2
		        expect "#"
		        send "show route\r"
		        sleep 0.2
		        expect "#"
		        send "show arp\r"
		        sleep 0.2
		        expect "#"
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "show logging\r"
		        sleep 0.2
		        expect "#"
		        send "show ip address\r"
		        sleep 0.2
		        expect "#"
		        send "changeto context ctx2\r"
		        sleep 0.2
		        expect "#"
		        send "show route\r"
		        sleep 0.2
		        expect "#"
		        send "show arp\r"
		        sleep 0.2
		        expect "#"
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "show logging\r"
		        sleep 0.2
		        expect "#"
		        send "show ip address\r"
		        sleep 0.2
                expect "#"
		        send "show clock\r"
		        sleep 0.2
		        send "exit\r"
		    }
		    "Password:" {
		        # This device does not require a username
		        send "$device_password\r"
				sleep 1
                expect {
                    "Password" {
                    # Telnet prompt did not appear, connection failed
                    puts "Unable to connect to device: $device_name, IP: $device_ip"
                    set fp [open $backup_error_file a]
                    puts $fp "$device_name $device_ip $today ===failed=== "
                    close $fp
                    continue
                    }
		            ">" {
		                send "en\r"
		                expect "Password:|#"
		                send "$device_enablepassword\r"
		                expect "#"
		            }
		            "#" {
		                # Do nothing and continue to the next command
		            }
		        }
		        send "terminal len 0\r"
				expect {
		            "ERROR: % Invalid input detected at '^' marker." {
		                send "terminal page 0\r"
		                expect "#"
		            }
		            "#" {
		                # Do nothing and continue to the next command
		            }
		        }					
		        expect -timeout 1 "#"
		        send "show inventory\r"
		        sleep 0.2
		        expect "#"
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "show inv\r"
		        expect "#"				
		        send "show ver\r"
		        expect "#"						
		        send "changeto system\r"
		        sleep 0.2
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "changeto context ctx1\r"
		        sleep 0.2
		        expect "#"
		        send "show route\r"
		        sleep 0.2
		        expect "#"
		        send "show arp\r"
		        sleep 0.2
		        expect "#"
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "show logging\r"
		        sleep 0.2
		        expect "#"
		        send "show ip address\r"
		        sleep 0.2
		        expect "#"
		        send "changeto context ctx2\r"
		        sleep 0.2
		        expect "#"
		        send "show route\r"
		        sleep 0.2
		        expect "#"
		        send "show arp\r"
		        sleep 0.2
		        expect "#"
		        send "show run\r"
		        sleep 0.2
		        expect "#"
		        send "show logging\r"
		        sleep 0.2
		        expect "#"
		        send "show ip address\r"
		        sleep 0.2
                expect "#"
		        send "show clock\r"
				sleep 1
		        send "exit\r"
        }           
        timeout {
            # Telnet prompt did not appear, connection failed
            puts "Unable to connect to device: $device_name, IP: $device_ip"
            set fp [open $backup_error_file a]
            puts $fp "$device_name $device_ip $today ===failed=== "
            close $fp
            continue
        }
    }
    expect eof
 # Check if backup file exists and log the result
    if {[file exists $log_file]} {
        puts "$log_file exists."
        set fp [open $backup_error_file a]
        puts $fp "$device_name $device_ip $today ok"
        close $fp
        log_file -noappend
    } else {
        set error_message "No backup found for device: $device_name, IP: $device_ip, Date: $today"
        puts $error_message
        set fp [open $backup_error_file a]
        puts $fp "No backup found for device: $device_name, IP: $device_ip, Date: $today"
        close $fp
    }
        log_file -noappend
}

# Count the number of successful and failed devices
set success_count 0
set failed_count 0
set fp [open $backup_error_file r]
while {[gets $fp line] != -1} {
    if {[string match "*ok" $line]} {
        incr success_count
    } elseif {[string match "*failed*" $line]} {
        incr failed_count
    }
}
close $fp

# Output the results to the error file
set fp [open $backup_error_file a]
puts $fp "\nBackup completed!"
puts $fp "Successfully backed up devices: $success_count"
puts $fp "Failed devices: $failed_count"
close $fp


set log_dir_clean "/etc/ansible/playbook/DatacenterTOR_backup/Tor-test"

# Use the "find" command to locate all ".txt" files in the directory
# and pass them to "sed" for text cleaning
spawn sh -c {find /etc/ansible/playbook/DatacenterTOR_backup/ -name "*.txt" -type f -exec sed -i '/% Invalid input detected/d; s/[[:space:]]\{1,\}\^//' {} +}
expect eof