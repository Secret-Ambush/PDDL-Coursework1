(define (domain lunar-extended)
    (:requirements :strips :typing)

    ; -------------------------------
    ; Types
    ; -------------------------------

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
        ;Astronaut positions
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

        ;Data handling
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
        :precondition (and
            (not (lander-placed ?la))
            (possible-lander-location ?l)
        )
        :effect (and
            (lander-placed ?la)
            (lander-at ?la ?l)
        )
    )

    ; Moving Astronaunts
    (:action move-astronaut-to-room
        :parameters (?a - astronaut ?la - lander ?r - room)
        :precondition (and
            (astronaut-assigned-to ?a ?la)
            (not (astronaut-at-room ?a ?r))
        )
        :effect (and
            (astronaut-at-room ?a ?r)
        )
    )

    ; Deploy rover from lander
    (:action deploy-rover
        :parameters (?a - astronaut ?d - dockingBay ?r - rover ?la - lander ?l - location)
        :precondition (and
            (lander-placed ?la)
            (lander-at ?la ?l)
            (astronaut-at-room ?a ?d)
            (rover-belongs-to ?r ?la)
            (not (rover-deployed ?r))
        )
        :effect (and
            (rover-deployed ?r)
            (rover-at ?r ?l)
        )
    )

    ; Move rover between connected locations
    (:action move
        :parameters (?r - rover ?from - location ?to - location)
        :precondition (and
            (rover-at ?r ?from)
            (path-from-to ?from ?to)
            (rover-deployed ?r)
        )
        :effect (and
            (not (rover-at ?r ?from))
            (rover-at ?r ?to)
        )
    )

    ; Take image at location
    (:action take-image
        :parameters (?r - rover ?img - image ?l - location)
        :precondition (and
            (rover-at ?r ?l)
            (image-at ?img ?l)
            (has-mem-space ?r)
            (not (collected-data ?img))
        )
        :effect (and
            (not(has-mem-space ?r))
            (image-ready-for-transmission ?img)
        )
    )

    ; Perform scan at location
    (:action perform-scan
        :parameters (?r - rover ?sc - scan ?l - location)
        :precondition (and
            (rover-at ?r ?l)
            (scan-at ?sc ?l)
            (has-mem-space ?r)
            (not (collected-data ?sc))
        )
        :effect (and
            (not (has-mem-space ?r))
            (scan-ready-for-transmission ?sc)
        )
    )

    ; Transmit data to lander
    (:action transmit-data
        :parameters (?r - rover ?a - astronaut ?c - controlRoom ?data - data ?la - lander)
        :precondition (and
            (astronaut-assigned-to ?a ?la)
            (astronaut-at-room ?a ?c)
            (not (has-mem-space ?r))
            (or (image-ready-for-transmission ?data) (scan-ready-for-transmission ?data))
        )
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
        :precondition (and
            (rover-at ?r ?l)
            (sample-at ?s ?l)
            (not (carrying-sample ?r ?s))
        )
        :effect (and
            (carrying-sample ?r ?s)
            (not (sample-at ?s ?l))
        )
    )

    ; Drop sample at lander
    (:action drop-sample
        :parameters (?r - rover ?a - astronaut ?d - dockingBay ?s - sample ?la - lander ?l - location)
        :precondition (and
            (carrying-sample ?r ?s)
            (astronaut-assigned-to ?a ?la)
            (astronaut-at-room ?a ?d)
            (rover-at ?r ?l)
            (lander-at ?la ?l)
            (not (lander-full ?la))
            (rover-belongs-to ?r ?la)
        )
        :effect (and
            (not (carrying-sample ?r ?s))
            (sample-stored ?s ?la)
            (lander-full ?la)
        )
    )
)
