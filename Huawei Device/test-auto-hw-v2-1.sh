#!/usr/bin/expect
###
 # @Descripttion: This program is the property of the Digital China project
 # @version: 2.1
 # @Author: Zhang Boqian (Daniel)
 # @Date: 2023-02-13 09:49:23
 # @LastEditors: Daniel
 # @LastEditTime: 2023-03-01 10:16:31
 # 2.1版
 # 1 集成思科备份程序V2.7版
 # 2 备份生成的日志中对于设备上无法运行的检测命令会生成无效信息反馈，清理备份文件中的无效信息
### 
set timeout 120
#Read username, password, and enable password from TOR-Huawei
set fp [open "/zbq/TOR-Huawei" r]
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
#Read device names, IP addresses, and per-device credentials from TOR-Huawei
set devices {}
set fp [open "/zbq/TOR-Huawei" r]
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
		        expect {
		            "Error: " {
				 # Telnet prompt did not appear, connection failed
            		puts "Unable to connect to device: $device_name, IP: $device_ip"
            		set fp [open $backup_error_file a]
            		puts $fp "$device_name $device_ip $today ===failed=== "
            		close $fp	
		            continue
		            }
		            ">" {
						send "screen-length 0 te\r"
						expect ">"
						send "sy\r"
		                expect "Password:"
		                send "$device_enablepassword\r"
		                expect "]"
		                # Do nothing and continue to the next command
		            }
		        }
 		        expect -timeout 1 "]"
			    send "display cu\r"
		        sleep 0.2
		        expect "]"
		        send "display version\r"
		        sleep 0.2
		        expect "]"
		        send "display interface brief\r"
		        sleep 0.2
		        expect "]"
		        send "display device\r"
		        sleep 0.2
		        expect "]"
		        send "display cpu-usage\r"
		        sleep 0.2
		        expect "]"
		        send "display memory\r"
		        sleep 0.2
		        expect "]"
		        send "display temperature\r"
		        sleep 0.2
		        expect "]"
		        send "display fan\r"
		        sleep 0.2
		        expect "]"
		        send "display power\r"
		        sleep 0.2
		        expect "]"
		        send "display arp\r"
		        sleep 0.2
		        expect "]"
		        send "display ip routing-table\r"
		        sleep 0.2
		        expect "]"
		        send "display vlan\r"
		        sleep 0.2
		        expect "]"
		        send "display mac-address\r"
		        sleep 0.2
		        expect "]"
		        send "display stp\r"
		        sleep 0.2
		        expect "]"
		        send "display logbuffer\r"
		        sleep 0.2
		        expect "]"
		        send "display interface\r"
		        sleep 0.2
		        expect "]"
		        send "dis interface transceiver\r"
		        sleep 0.2
		        expect "]"
		        send "display ntp-service status\r"
		        sleep 0.2
		        expect "]"
		        send "display ip routing-table summary\r"
		        sleep 0.2
		        expect "]"
		        send "display interface counters errors\r"
		        sleep 0.2
		        expect "]"
		        send "display lldp neighbor\r"
		        sleep 0.2
		        expect "]"
		        send "display acl all\r"
		        sleep 0.2
		        expect "]"
		        send "display vrrp\r"
		        sleep 0.2
		        expect "]"
		        send "display ospf peer\r"
		        sleep 0.2
		        expect "]"
		        send "dis time all\r"
		        sleep 0.2
		        expect "Current time is"
		        send "quit\r"
		        sleep 0.2
		        send "quit\r"
		    }
		    "Password:" {
		        # This device does not require a username
		        send "$device_password\r"
		        expect {
		            ">" {
						send "screen-length 0 te\r"
		                expect ">"
		                send "sy\r"
		                expect "Password:|#"
		                send "$device_enablepassword\r"
		                expect "]"
		            }
		            "]" {
		                # Do nothing and continue to the next command
		            }
		        }				
		        expect -timeout 1 "]"
			    send "display cu\r"
		        sleep 0.2
		        expect "]"
				send "display version\r"
		        sleep 0.2
		        expect "]"
		        send "display interface brief\r"
		        sleep 0.2
		        expect "]"
		        send "display device\r"
		        sleep 0.2
		        expect "]"
		        send "display cpu-usage\r"
		        sleep 0.2
		        expect "]"
		        send "display memory\r"
		        sleep 0.2
		        expect "]"
		        send "display temperature\r"
		        sleep 0.2
		        expect "]"
		        send "display fan\r"
		        sleep 0.2
		        expect "]"
		        send "display power\r"
		        sleep 0.2
		        expect "]"
		        send "display arp\r"
		        sleep 0.2
		        expect "]"
		        send "display ip routing-table\r"
		        sleep 0.2
		        expect "]"
		        send "display vlan\r"
		        sleep 0.2
		        expect "]"
		        send "display mac-address\r"
		        sleep 0.2
		        expect "]"
		        send "display stp\r"
		        sleep 0.2
		        expect "]"
		        send "display logbuffer\r"
		        sleep 0.2
		        expect "]"
		        send "display interface\r"
		        sleep 0.2
		        expect "]"
		        send "dis interface transceiver\r"
		        sleep 0.2
		        expect "]"
		        send "display ntp-service status\r"
		        sleep 0.2
		        expect "]"
		        send "display ip routing-table summary\r"
		        sleep 0.2
		        expect "]"
		        send "display interface counters errors\r"
		        sleep 0.2
		        expect "]"
		        send "display lldp neighbor\r"
		        sleep 0.2
		        expect "]"
		        send "display acl all\r"
		        sleep 0.2
		        expect "]"
		        send "display vrrp\r"
		        sleep 0.2
		        expect "]"
		        send "display ospf peer\r"
		        sleep 0.2
		        expect "]"
		        send "dis time all\r"
		        sleep 0.2
		        expect "Current time is"
		        send "quit\r"
		        sleep 0.2
		        send "quit\r"
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

# Use the "find" command to locate all ".txt" files in the directory
# and pass them to "sed" for text cleaning
spawn sh -c {find /etc/ansible/playbook/DatacenterTOR_backup/ -name "*.txt" -type f -exec sed -i '/% Invalid input detected/d; s/[[:space:]]\{1,\}\^//' {} +}
expect eof