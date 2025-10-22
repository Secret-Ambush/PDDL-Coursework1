(define (domain lunar)
    (:requirements :strips :typing)

    ; -------------------------------
    ; Types
    ; -------------------------------

    (:types
        rover
        lander
        location
        sample
        data
        image - data
        scan - data
    )

    ; -------------------------------
    ; Predicates
    ; -------------------------------

    (:predicates
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

    ; Action for optimising placement of lander 
    (:action place-lander
        :parameters (?la - lander ?l - location)
        ; Preconditions: the lander has not been placed and the location is designated as valid
        :precondition (and
            (not (lander-placed ?la))
            (possible-lander-location ?l)
        )
        ; Effects: mark the lander as placed and record its absolute position
        :effect (and
            (lander-placed ?la)
            (lander-at ?la ?l)
        )
    )

    ; Deploy rover from lander
    (:action deploy-rover
        :parameters (?r - rover ?la - lander ?l - location)
        ; Preconditions: lander is on the surface, rover belongs to it, and has not yet been deployed
        :precondition (and
            (lander-placed ?la)
            (lander-at ?la ?l)
            (rover-belongs-to ?r ?la)
            (not (rover-deployed ?r))
        )
        ; Effects: flag the rover as deployed and co-relate it with the lander
        :effect (and
            (rover-deployed ?r)
            (rover-at ?r ?l)
        )
    )

    ; Move rover between connected locations
    (:action move
        :parameters (?r - rover ?from - location ?to - location)
        ; Preconditions: rover must be deployed, currently at the origin, and the direct path must exist
        :precondition (and
            (rover-at ?r ?from)
            (path-from-to ?from ?to)
            (rover-deployed ?r)
        )
        ; Effects: update the rover position to the destination and clear the previous one
        :effect (and
            (not (rover-at ?r ?from))
            (rover-at ?r ?to)
        )
    )

    ; Take image at location
    (:action take-image
        :parameters (?r - rover ?img - image ?l - location)
        ; Preconditions: rover must have memory space and be co-located with the image target
        :precondition (and
            (rover-at ?r ?l)
            (image-at ?img ?l)
            (has-mem-space ?r)
            (not (collected-data ?img))
        )
        ; Effects: consume the rover memory slot and queue the image for transmission
        :effect (and
            (not(has-mem-space ?r))
            (image-ready-for-transmission ?img)
        )
    )

    ; Perform scan at location
    (:action perform-scan
        :parameters (?r - rover ?sc - scan ?l - location)
        ; Preconditions: rover must have memory space and be at the scan site
        :precondition (and
            (rover-at ?r ?l)
            (scan-at ?sc ?l)
            (has-mem-space ?r)
            (not (collected-data ?sc))
        )
        ; Effects: reserve the rover memory slot and mark the scan as ready to send
        :effect (and
            (not (has-mem-space ?r))
            (scan-ready-for-transmission ?sc)
        )
    )

    ; Transmiting data (image/scan) to lander
    (:action transmit-data
        :parameters (?r - rover ?data - data ?la - lander)
        ; Preconditions: rover memory is full and either an image or scan is flagged for transmission
        :precondition (and
            (not (has-mem-space ?r))
            (or (image-ready-for-transmission ?data) (scan-ready-for-transmission ?data))
        )
        ; Effects: free rover memory, clear the transmission flags, and register the data as collected
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
        ; Preconditions: rover is at the sample site and not already carrying that sample
        :precondition (and
            (rover-at ?r ?l)
            (sample-at ?s ?l)
            (not (carrying-sample ?r ?s))
        )
        ; Effects: load the sample onto the rover and remove it from the surface
        :effect (and
            (carrying-sample ?r ?s)
            (not (sample-at ?s ?l))
        )
    )

    ; Drop sample at lander
    (:action drop-sample
        :parameters (?r - rover ?s - sample ?la - lander ?l - location)
        ; Preconditions: rover carries the sample, is at its lander, and the lander has available storage
        :precondition (and
            (carrying-sample ?r ?s)
            (rover-at ?r ?l)
            (lander-at ?la ?l)
            (not (lander-full ?la))
            (rover-belongs-to ?r ?la)
        )
        ; Effects: unload the sample into the lander and mark storage as full
        :effect (and
            (not (carrying-sample ?r ?s))
            (sample-stored ?s ?la)
            (lander-full ?la)
        )
    )
)

