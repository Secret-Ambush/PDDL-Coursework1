(define (domain lunar-extended)
    (:requirements :strips :typing)

    ; -------------------------------
    ; Types
    ; -------------------------------

    ; New types of astronaunt, room (parent type), controlRoom, dockingBay (children types)
    (:types
        rover
        lander
        room
        controlRoom - room
        dockingBay - room
        location
        sample
        data
        image - data
        scan - data
        astronaut
    )

    ; -------------------------------
    ; Predicates
    ; -------------------------------

    (:predicates
        ; Astronaut positions
        (astronaut-assigned-to ?a - astronaut ?la - lander)
        (astronaut-at-room ?a - astronaut ?r - room)

        ; Rover and Lander positions
        (rover-at ?r - rover ?l - location)
        (lander-at ?la - lander ?l - location)

        ; Lander placement
        (lander-placed ?la - lander)
        (possible-lander-location ?l - location)
        
        ; Directional path connectivity
        (path-from-to ?from - location ?to - location)
        
        ; Rover deployment and association
        (rover-belongs-to ?r - rover ?la - lander)
        (rover-deployed ?r - rover)
        
        ; Rover memory management
        (has-mem-space ?r - rover)
        
        ; Check if the corresponding image/scan is going to be transmitted
        (image-ready-for-transmission ?img - data)
        (scan-ready-for-transmission ?sc - data)
        
        ; Image, scan and sample locations
        (image-at ?img - image ?l - location)
        (scan-at ?sc - scan ?l - location)
        (sample-at ?s - sample ?l - location)

        ; Data handling
        (collected-data ?d - data)
        
        ; Sample handling
        (carrying-sample ?r - rover ?s - sample)
        (sample-stored ?s - sample ?la - lander)
        (lander-full ?la - lander)
    )

    ; -------------------------------
    ; Actions
    ; -------------------------------

    ; Placement of landers - one-time placement, can't be changed
    (:action place-lander
        :parameters (?la - lander ?l - location)
        ; Preconditions: lander must still be unplaced and the site must be validated
        :precondition (and
            (not (lander-placed ?la))
            (possible-lander-location ?l)
        )
        ; Effects: commit the lander to the site and mark it as placed
        :effect (and
            (lander-placed ?la)
            (lander-at ?la ?l)
        )
    )

    ; Moving Astronaunts between Room
    (:action move-astronaut-to-room
        :parameters (?a - astronaut ?la - lander ?r - room)
        ; Preconditions: astronaut belongs to the lander and is not already in the destination room
        :precondition (and
            (astronaut-assigned-to ?a ?la)
            (not (astronaut-at-room ?a ?r))
        )
        ; Effects: relocate the astronaut to the target room
        :effect (and
            (astronaut-at-room ?a ?r)
        )
    )

    ; Deploy rover from lander
    (:action deploy-rover
        :parameters (?a - astronaut ?d - dockingBay ?r - rover ?la - lander ?l - location)
        ; Preconditions: lander is on site, assigned astronaut is in the docking bay, and rover is still undeployed
        :precondition (and
            (lander-placed ?la)
            (lander-at ?la ?l)
            (astronaut-at-room ?a ?d)
            (rover-belongs-to ?r ?la)
            (not (rover-deployed ?r))
        )
        ; Effects: mark the rover as deployed and place it at the lander's exterior location
        :effect (and
            (rover-deployed ?r)
            (rover-at ?r ?l)
        )
    )

    ; Move rover between connected locations
    (:action move
        :parameters (?r - rover ?from - location ?to - location)
        ; Preconditions: rover must be deployed, currently at the origin, and there must be a direct path
        :precondition (and
            (rover-at ?r ?from)
            (path-from-to ?from ?to)
            (rover-deployed ?r)
        )
        ; Effects: shift the rover to the destination and clear the previous position
        :effect (and
            (not (rover-at ?r ?from))
            (rover-at ?r ?to)
        )
    )

    ; Take image at location
    (:action take-image
        :parameters (?r - rover ?img - image ?l - location)
        ; Preconditions: rover must be at the image site with free memory and the image cannot be collected yet
        :precondition (and
            (rover-at ?r ?l)
            (image-at ?img ?l)
            (has-mem-space ?r)
            (not (collected-data ?img))
        )
        ; Effects: consume the memory slot and flag the image for transmission
        :effect (and
            (not(has-mem-space ?r))
            (image-ready-for-transmission ?img)
        )
    )

    ; Perform scan at location
    (:action perform-scan
        :parameters (?r - rover ?sc - scan ?l - location)
        ; Preconditions: rover must be stationed at the scan location with available memory
        :precondition (and
            (rover-at ?r ?l)
            (scan-at ?sc ?l)
            (has-mem-space ?r)
            (not (collected-data ?sc))
        )
        ; Effects: reserve the memory slot and flag the scan data for transmission
        :effect (and
            (not (has-mem-space ?r))
            (scan-ready-for-transmission ?sc)
        )
    )

    ; NEW CONDITION: assigned astronaut must be in the control room and rover must hold unsent data
    (:action transmit-data
        :parameters (?r - rover ?a - astronaut ?c - controlRoom ?data - data ?la - lander)
        ; Preconditions: assigned astronaut must be in the control room and rover must hold unsent data
        :precondition (and
            (astronaut-assigned-to ?a ?la)
            (astronaut-at-room ?a ?c)
            (not (has-mem-space ?r))
            (or (image-ready-for-transmission ?data) (scan-ready-for-transmission ?data))
        )
        ; Effects: clear the rover's memory, reset transmission flags, and mark the data as collected
        :effect (and
            (has-mem-space ?r)
            (not (image-ready-for-transmission ?data))
            (not (scan-ready-for-transmission ?data)) 
            (collected-data ?data)
        )
    )

    ; Pick up sample from location
    (:action pick-sample
        :parameters (?r - rover ?s - sample ?l - location)
        ; Preconditions: rover is co-located with the sample and currently empty-handed
        :precondition (and
            (rover-at ?r ?l)
            (sample-at ?s ?l)
            (not (carrying-sample ?r ?s))
        )
        ; Effects: load the sample onto the rover and remove it from the location map
        :effect (and
            (carrying-sample ?r ?s)
            (not (sample-at ?s ?l))
        )
    )

    ; NEW CONDITION: rover and astronaut are ready at the lander, storage has capacity, and rover carries the sample
    (:action drop-sample
        :parameters (?r - rover ?a - astronaut ?d - dockingBay ?s - sample ?la - lander ?l - location)
        ; Preconditions: rover and astronaut are ready at the lander, storage has capacity, and rover carries the sample
        :precondition (and
            (carrying-sample ?r ?s)
            (astronaut-assigned-to ?a ?la)
            (astronaut-at-room ?a ?d)
            (rover-at ?r ?l)
            (lander-at ?la ?l)
            (not (lander-full ?la))
            (rover-belongs-to ?r ?la)
        )
        ; Effects: unload the sample into the lander and mark it as full
        :effect (and
            (not (carrying-sample ?r ?s))
            (sample-stored ?s ?la)
            (lander-full ?la)
        )
    )
)

