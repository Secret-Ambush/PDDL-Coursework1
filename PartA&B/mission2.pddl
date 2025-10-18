(define (problem lunar-mission-2)
    (:domain lunar)

    (:objects
        wp1 wp2 wp3 wp4 wp5 wp6 - location
        rover1 rover2 - rover
        lander1 lander2 - lander
        sample-wp1 sample-wp5 - sample
        img-wp2 img-wp3 - image
        scan-wp4 scan-wp6 - scan
    )

    (:init
        ; Lander setup
        (lander-placed lander1)
        (lander-at lander1 wp2)

        (not (lander-placed lander2))
        (possible-lander-location wp1)
        (possible-lander-location wp2)
        (possible-lander-location wp3)
        (possible-lander-location wp4)
        (possible-lander-location wp5)
        
        ; Rover setup
        (rover-belongs-to rover1 lander1)
        (rover-belongs-to rover2 lander2)
        (has-mem-space rover1)
        (has-mem-space rover2)
        
        ; Rover1 starts already deployed at wp2
        (rover-deployed rover1)
        (rover-at rover1 wp2)
        
        ; Rover2 starts undeployed
        (not (rover-deployed rover2))
        
        ; Sample locations
        (sample-at sample-wp1 wp1)
        (sample-at sample-wp5 wp5)
        
        ; Image and scan locations
        (image-at img-wp2 wp2)
        (image-at img-wp3 wp3)
        (scan-at scan-wp4 wp4)
        (scan-at scan-wp6 wp6)
        
        ; Directional paths
        (path-from-to wp1 wp2)
        (path-from-to wp2 wp1)
        (path-from-to wp2 wp3)
        (path-from-to wp2 wp4)
        (path-from-to wp3 wp5)
        (path-from-to wp4 wp2)
        (path-from-to wp5 wp3)
        (path-from-to wp5 wp6)
        (path-from-to wp6 wp4)
    )

    (:goal
        (and
            (lander-placed lander2)
            ; Save image at waypoint 3
            (collected-data img-wp3)
            ; Save scan at waypoint 4
            (collected-data scan-wp4)
            ; Save image at waypoint 2
            (collected-data img-wp2)
            ; Save scan at waypoint 6
            (collected-data scan-wp6)
            ; Collect sample from waypoint 5
            (sample-stored sample-wp5 lander1)
            ; Collect sample from waypoint 1
            (sample-stored sample-wp1 lander2)
        )
    )
)