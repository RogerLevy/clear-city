class_name TimingMode

enum Mode {
    ## Uses the global default timing mode (beat.gd)
    DEFAULT,
    ## Real-time seconds (1 unit = 1 second)
    NORMAL,
    ## Beat-scaled time (1 unit = 1 beat)
    MUSICAL
}
