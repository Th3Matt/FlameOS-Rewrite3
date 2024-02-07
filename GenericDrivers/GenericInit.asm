
GenericDrivers:
    .init:
        call GenericKeyboardD.init
        call GenericDiskD.init
        ret


%include "GenericDrivers/GenericKeyboardDriver.asm"
%include "GenericDrivers/GenericDiskDriver.asm"
