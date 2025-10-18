(define (problem lunar-mission-1)
    (:domain lunar)

    (:objects
        wp1 wp2 wp3 wp4 wp5 - location
        rover1 - rover
        lander1 - lander
        sample-wp1 - sample
        img-wp5 - image
        scan-wp3 - scan
    )

    (:init
        ; Lander and Rover setup
        (not (lander-placed lander1))
        (possible-lander-location wp1)
        (possible-lander-location wp2)
        (possible-lander-location wp3)
        (possible-lander-location wp4)
        (possible-lander-location wp5)

        (rover-belongs-to rover1 lander1)
        (has-mem-space rover1)
        
        ; Sample location
        (sample-at sample-wp1 wp1)
        
        ; Image and scan-wp3 locations
        (image-at img-wp5 wp5)
        (scan-at scan-wp3 wp3)

        ; Not collected items
        (not (collected-data img-wp5))
        (not (collected-data scan-wp3))
        (not (sample-stored sample-wp1 lander1))
        
        ; Directional path network (from Mission 1 diagram)
        (path-from-to wp1 wp2)
        (path-from-to wp2 wp3)
        (path-from-to wp3 wp5)
        (path-from-to wp5 wp1)
        (path-from-to wp1 wp4)
        (path-from-to wp4 wp3)
    )

    (:goal
        (and
            (lander-placed lander1)
            ; Save image at waypoint 5
            (collected-data img-wp5)
            ; Save scan at waypoint 3
            (collected-data scan-wp3)
            ; Collect sample from waypoint 1
            (sample-stored sample-wp1 lander1)
        )
    )
)