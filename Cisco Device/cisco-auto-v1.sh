#!/usr/bin/expect
###
 # @Descripttion: This program is the property of the Digital China project
 # @version: 1.0
 # @Author: Zhang Boqian (Daniel)
 # @Date: 2023-02-20 09:49:23
 # @LastEditors: Daniel
 # @LastEditTime: 2023-03-21 09:17:28
 # 原始程序测试版V3
 ### 
set timeout 120
#Read username, password, and enable password from shangdi.txt
set fp [open "/zbq/shangdi.txt" r]
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
#Read device names, IP addresses, and per-device credentials from shangdi.txt
set devices {}
set fp [open "/zbq/shangdi.txt" r]
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
            "telnet: connect to address"
    continue
    }
    expect {
		    -re "login:|Username:" {
		        # This device requires a username
		        send "$device_username\r"
		        expect "Password:"
		        send "$device_password\r"
				sleep 1
                expect {
                   -re "Authentication failed|Login invalid|% Access" {
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
				expect { 
			         	"Access denied"
	   	                continue
				}
			        expect -timeout 2 "#"
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
		        send "show module\r"
		        sleep 0.2
		        expect "#"
		        send "show version\r"
		        sleep 0.2
		        send "show processes cpu\r"
		        sleep 0.2
		        expect "#"
		        send "show processes memory\r"
		        sleep 0.2
		        expect "#"
		        send "show ip route\r"
		        sleep 0.2
		        expect "#"
		        send "show arp\r"
		        sleep 0.2
		        expect "#"
		        send "show mac-address-table\r"
		        sleep 0.2
		        expect "#"
		        send "show vlan\r"
		        sleep 0.2
		        expect "#"
		        send "show logging\r"
		        sleep 0.2
		        expect "#"
		        send "show snmp\r"
		        sleep 0.2
		        expect "#"
		        send "show power\r"
		        sleep 0.2
		        expect "#"
		        send "show environment\r"
		        sleep 0.2
		        expect "#"
		        send "show ip interface brief\r"
		        sleep 0.2
		        expect "#"
		        send "show interface status\r"
		        sleep 0.2
		        expect "#"
		        send "show interface counters\r"
		        sleep 0.2
		        expect "#"
		        send "show interface transceiver\r"
		        sleep 0.2
		        expect "#"
		        send "show ip interface brief\r"
		        sleep 0.2
		        expect "#"
		        send "show ip protocols\r"
		        sleep 0.2
		        expect "#"
		        send "show ip ospf database\r"
		        sleep 0.2
		        expect "#"
		        send "show ip ospf neighbor\r"
		        sleep 0.2
		        expect "#"
		        send "show ip ospf neighbor det\r"
		        sleep 0.2
		        expect "#"
		        send "show cdp neighbors\r"
		        sleep 0.2
		        expect "#"
		        send "show cdp neighbors det\r"
		        sleep 0.2
		        expect "#"
		        send "show lldp neighbors\r"
		        sleep 0.2
		        expect "#"
		        send "show ntp status\r"
		        sleep 0.2
		        expect "#"
		        send "show ip interface\r"
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
                    -re  "Password|Login invalid" {
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
		        send "show module\r"
		        sleep 0.2
		        expect "#"
		        send "show version\r"
		        sleep 0.2
		        send "show processes cpu\r"
		        sleep 0.2
		        expect "#"
		        send "show processes memory\r"
		        sleep 0.2
		        expect "#"
		        send "show ip route\r"
		        sleep 0.2
		        expect "#"
		        send "show arp\r"
		        sleep 0.2
		        expect "#"
		        send "show mac-address-table\r"
		        sleep 0.2
		        expect "#"
		        send "show vlan\r"
		        sleep 0.2
		        expect "#"
		        send "show logging\r"
		        sleep 0.2
		        expect "#"
		        send "show snmp\r"
		        sleep 0.2
		        expect "#"
		        send "show power\r"
		        sleep 0.2
		        expect "#"
		        send "show environment\r"
		        sleep 0.2
		        expect "#"
		        send "show ip interface brief\r"
		        sleep 0.2
		        expect "#"
		        send "show interface status\r"
		        sleep 0.2
		        expect "#"
		        send "show interface counters\r"
		        sleep 0.2
		        expect "#"
		        send "show interface transceiver\r"
		        sleep 0.2
		        expect "#"
		        send "show ip interface brief\r"
		        sleep 0.2
		        expect "#"
		        send "show ip protocols\r"
		        sleep 0.2
		        expect "#"
		        send "show ip ospf database\r"
		        sleep 0.2
		        expect "#"
		        send "show ip ospf neighbor\r"
		        sleep 0.2
		        expect "#"
		        send "show ip ospf neighbor det\r"
		        sleep 0.2
		        expect "#"
		        send "show cdp neighbors\r"
		        sleep 0.2
		        expect "#"
		        send "show cdp neighbors det\r"
		        sleep 0.2
		        expect "#"
		        send "show lldp neighbors\r"
		        sleep 0.2
		        expect "#"
		        send "show ntp status\r"
		        sleep 0.2
		        expect "#"
		        send "show ip interface\r"
		        sleep 0.2
                        expect "#"
		        send "show clock\r"
		        expect "#"
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


# Use the "find" command to locate all ".txt" files in the directory
# and pass them to "sed" for text cleaning
spawn sh -c {find /etc/ansible/playbook/DatacenterTOR_backup/ -name "*.txt" -type f -exec sed -i '/% Invalid input detected/d; s/[[:space:]]\{1,\}\^//' {} +}
expect eof
