foreach tool : ['depmod',
                'insmod',
                'lsmod',
                'modinfo',
                'modprobe',
                'rmmod',
                ]
  custom_target(
    tool,
    build_by_default : true,
    command : ['ln', '-sf', '../kmod', '@OUTPUT@'],
    output : [tool],
    depends : [kmod])
endforeach
