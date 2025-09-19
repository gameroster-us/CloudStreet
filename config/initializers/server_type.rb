  my_script = "script/CPUinfo.sh"
  cpu_info = %x( #{my_script} )
  cpu_info.delete!("\n")
  CPU_INFO = (cpu_info == 'unknown') ? nil : cpu_info
