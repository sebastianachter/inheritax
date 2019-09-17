; basic model was developed by Uri Wilensky (1998)
; modified and extended by Thomas Buda und Tim Niklas Winkelbach in 2018 for Technische Universität Hamburg (2018)
; modified and extended by Marco Lutz and Jan Teckentrup in 2019 for Technische Universität Hamburg (2019)

globals
[
  max-utility                         ; maximum amount of utility any patch can have at the beginning
  utility-counter                     ; counter for the total amount of utility within the simulation
  gini-index-reserve                  ; variable needed to plot the Gini-index over time
  lorenz-points                       ; array which holds the points for plotting the lorenz curve
  family                              ; family-counter counts +1 when 2 agents marry in order to provide the family-ID
  immigration-number-people           ; absolute number of people who will immigrate to the population
  inheritance-tax-allowance-absolute  ; absolute number of the inheritance-tax-allowance
  inflation-factor                    ; tracks the inflation in the system
  starting-utility                    ; total utility in the system after setup

  initial-percentage-higher-class     ; the percentage of people who will be created in the higher class at the beginning
  initial-percentage-middle-class     ; the percentage of people who will be created in the middle class at the beginning
  initial-percentage-lower-class      ; the percentage of people who will be created in the lower class at the beginning

  minimum-age-to-reproduce            ; the minimum age when the turtles are able to get children
  maximum-age-to-reproduce            ; the maximum age when the turtles are able to get children

  maximum-age-distant-relative        ; the maximum age a distant relative is allowed to have to receive inheritance money

  ;global variables for lower class turtles
  life-expectancy-low                 ; the life expectancy of the lower class people
  consumption-low                     ; the consumption per tick of the lower class people
  feed-low                            ; the amount of utility lower class people give to their children per tick
  wealth-low                          ; the initial wealth of the lower class people
  vision-low                          ; how far the lower class turtles can look to find the highest utility

  ;global variables for middle class turtles
  life-expectancy-middle              ; the life expectancy of the middle class people
  consumption-middle                  ; the consumption per tick of the middle class people
  feed-middle                         ; the amount of utility middle class people give to their children per tick
  wealth-middle                       ; the initial wealth of the middle class people
  vision-middle                       ; how far the lower class turtles can middle to find the highest utility

  ;global variables for higher class turtles
  life-expectancy-high                ; the life expectancy of the higher class people
  consumption-high                    ; the consumption per tick of the higher class people
  feed-high                           ; the amount of utility higher class people give to their children per tick
  wealth-high                         ; the initial wealth of the higher class people
  vision-high                         ; how far the higher class turtles can look to find the highest utility

  wealth-taxation                     ; the income tax rate for the upper class

]

patches-own
[
  utility-here      ; the current amount of utility on this patch
]

turtles-own
[
  age               ; how old a turtle is
  wealth            ; the amount of utility a turtle has
  consumption       ; how much utility a turtle consumes per tick
  vision            ; how many patches ahead a turtle can see
  sex               ; string if female or male
  adult             ; binary variable if age > 18
  married           ; string if married or unmarried
  family-ID         ; the family a turtle belongs to
  child-count       ; the number of children a female turtle has
  child-age         ; age of the children
  Partner-alive     ; string if the married partner of a turtle is still alive
  Partner-ID        ; the number ( "WHO") of the turtles married partner
  Child-ID-I        ; the number ( "WHO") of the first born child
  Child-ID-II       ; the number ( "WHO") of the second born child
  social-class      ; the social class a turtle gets born into (red/ green/ blue)
]

;;;
;;; SETUP AND HELPERS
;;;
;; sets the initial value for the global variables and calls other procedures to set up various parts of the world.
to setup
  clear-all

  ;; set global variables to appropriate values: these values shall be fixed before starting the analysis phase. Besides those, some values controlled by sliders could be fixed as well
  set max-utility 50
  set family 0
  set inflation-factor 1

  set initial-percentage-lower-class 0.23
  set initial-percentage-middle-class 0.58
  set initial-percentage-higher-class 0.19

  set minimum-age-to-reproduce 18
  set maximum-age-to-reproduce 50

  set life-expectancy-low 79
  set consumption-low 1
  set feed-low 1
  set wealth-low 1
  set vision-low 1

  set life-expectancy-middle 79
  set consumption-middle 2
  set feed-middle 2
  set wealth-middle 99
  set vision-middle 2

  set life-expectancy-high 79
  set consumption-high 4
  set feed-high 4
  set wealth-high 200
  set vision-high 3

  set maximum-age-distant-relative 55

  set wealth-taxation 0


  ;; call other procedures to set up various parts of the world
  setup-patches
  setup-turtles
  update-lorenz-and-gini
  update-utility-counter

  ;CHANGE
  set starting-utility utility-counter          ; the amount of utility in the system after setup gets saved

  reset-ticks
end

;; set up the initial amounts of utility each patch has, utility is the pendant to wealth
to setup-patches
  ;; give some patches the highest amount of utility possible at the beginning (max-utility) --
  ;; these patches are the "best land"

  ask patches
    [ set utility-here 0
      if (random-float 100.0) <= percent-best-land
        [ set utility-here max-utility] ]
  ;; spread that utility around the window a little and put a little back
  ;; into the patches that are the "best land" found above
  repeat 10
    [ diffuse utility-here 0.25 ]               ;spread the utility around
  ask patches
    [ set utility-here floor utility-here       ;round utility levels to whole numbers
      recolor-patch ]
end

;; patch procedure -- use color to indicate utility level. The scale goes from 0 to maximum utility multiplied with half of the inflation factor. This leads to good results regarding visibility.
to recolor-patch
  set pcolor scale-color yellow utility-here 0 (max-utility * inflation-factor  / 2)
end

;; set up the initial values for the turtle variables
to setup-turtles
  set-default-shape turtles "arrow"
  create-turtles num-adult-people * initial-percentage-lower-class
    [ move-to one-of patches              ; put turtles on a random patch
      set size 1.0                        ; makes them easier to see
      set-initial-turtle-vars-low ]
  create-turtles num-adult-people * initial-percentage-middle-class
    [ move-to one-of patches              ; put turtles on a random patch
      set size 1.0                        ; makes them easier to see
      set-initial-turtle-vars-middle ]
   create-turtles num-adult-people * initial-percentage-higher-class
    [ move-to one-of patches              ; put turtles on a random patch
      set size 1.0                        ; makes them easier to see
      set-initial-turtle-vars-high ]
recolor-turtles
set-initial-relationships
set-initial-children
end

;; set up the initial values for the lower class of turtles
to set-initial-turtle-vars-low
  face one-of neighbors4
  set age (random (life-expectancy-low  - 18) ) + 18           ; by adding 18 year after substracting 18 years from life expectancy, its ensured that the turtles in the start population are at leat 18 years old
  set adult true                        ; turtle is classified as an adult by setting the variable to true
  set consumption consumption-low
  set wealth wealth-low * inflation-factor
  set vision vision-low
  ifelse (random-float 1.0 <= 0.5)
   [set sex "M"]
    [set sex "F"]
  set married false
  set child-count 0
  set family-ID who * 2
end

;; set up the initial values for the middle class of turtles
to set-initial-turtle-vars-middle
  face one-of neighbors4
  set age (random (life-expectancy-middle - 18)) + 18
  set adult true
  set consumption consumption-middle
  set wealth wealth-middle * inflation-factor
  set vision vision-middle
  ifelse (random-float 1.0 <= 0.5)
   [set sex "M"]
    [set sex "F"]
  set married false
  set child-count 0
  set family-ID who * 2
end

;; set up the initial values for the upper class of turtles
to set-initial-turtle-vars-high
  face one-of neighbors4
  set age (random (life-expectancy-high  - 18)) + 18
  set adult true
  set consumption consumption-high
  set wealth wealth-high * inflation-factor
  set vision vision-high
  ifelse (random-float 1.0 <= 0.5)
   [set sex "M"]
    [set sex "F"]
  set married false
  set child-count 0
  set family-ID who * 2
end

;; Set the class of the turtles -- if a turtle has less than 70% of the median wealth, color it red (lower class).
;; If it has more than 150% of the median wealth, color it blue (upper classe). Else color it green (middle class)
;; the more utility a turtle owns, the further it is able to see on the field
;; to illustrate the advantage rich people have to increase their wealth.
;; consumption also depends on social class
to recolor-turtles
  let median-wealth median [wealth] of turtles
  ask turtles with [adult = true]
     [ ifelse (wealth <= (median-wealth * 0.7) )
        [ set color red
           set vision vision-low
           set consumption floor (consumption-low * inflation-factor)
        ]
        [ ifelse (wealth <= (median-wealth * 1.5))
          [ set color green
            set vision vision-middle
            set consumption floor (consumption-middle * inflation-factor)
          ]
            [ set color blue
              set vision vision-high
              set consumption floor (consumption-high * inflation-factor)
            ]
        ]
     ]
  ask turtles with [adult = false]
  [ set color white
    set vision vision-low
    set consumption floor (1 * inflation-factor)
  ]
end

;; In order to produce better results in a shorter amount of ticks many of the turtles get married and have children already in the setup process
;; Turtles chose a partner within their age range and get to marry them with a certain percentile chance, depending on their prospective partner's social class and their own
to set-initial-relationships
  ask turtles with [sex = "M" and adult = true]   ; Everyone out of the male population is granted the chance to marry a female in the setup process
  [
  let marriage random 100
  let match false
  let marry-ID 0
    if count turtles with [married = false and sex = "F" and adult = true and age <= ([age] of myself + 15) and age >= ([age] of myself - 15)] > 1
    [    ask one-of turtles with [married = false and sex = "F" and adult = true and family-ID != [family-ID] of myself and age <= ([age] of myself + 15) and age >= ([age] of myself - 15)]
     [ifelse color = [color] of myself
        [ if marriage  <= 90                      ; The chance to marry another turtle of the same social class is higher
        [set married  true
         set match true
         set partner-alive true
         set family (family + 1)
         set family-ID family * 2 + 1
         set partner-ID [who] of myself           ; a turtle save the own ID at a partners variable to find him/her on the field
         set marry-ID who
        ]]
      [if color != [color] of myself and
       marriage <= 30                             ; The chance to marry another turtle of another social class is lower
       [set married  true
        set match true
        set partner-alive true
        set family (family + 1)
        set family-ID family * 2 + 1
        set partner-ID [who] of myself
        set marry-ID who
       ]
      ]
     ]
      if match = true
    [ set married true
      set family-ID family * 2 + 1
      set partner-ID (marry-ID)                    ; the other turtle saves the own ID at a partners variable to find him/her on the field
      set partner-alive true
   ]
    ]
  ]
end

;; in addition to the initial adult population, the married couples can have children in the setup process
to set-initial-children
  ask turtles
  [
   let childbearing random 100
   if married and sex = "F" and age >= 35 and age <= 60 and childbearing <= 100  ; If the turtles fall within a certain age range, they can have children from the start
      [hatch 1 [set-child-initial-I]
        set child-count (child-count + 1)
      hatch 1 [set-child-initial-II]
          set child-count (child-count + 1)
    set child-age 0]
    ]
end

;; sets the initial values for the first born child
to set-child-initial-I                              ; set the starting variables for the first born initial child
  ifelse color = red
    [ set social-class red ]                        ; children get born into a social class, which determines the amount of utility they will receive from their parents with each tick
    [ ifelse color = green
     [set social-class green]
     [set social-class blue]
    ]
  set age random (17)                              ; first born child can be 0 to 17 years old
  set adult false
  face one-of neighbors4
  ifelse (random-float 1.0 <= 0.5)
   [set sex "M"]
    [set sex "F"]
  set married false
  set child-count 0
  set partner-ID 0
  set child-ID-I 0
  set child-ID-II 0
  set partner-alive false
  set color white                                   ; children are distinguishable by their white color
  set wealth 1
  ask turtles with [family-ID = [family-ID] of myself]  ; the new born has to save its ID in the variables of parents, that they can find it on the field
    [set child-ID-I [who] of myself]
end

;; sets the initial values for the second born child
to set-child-initial-II                             ; set the starting variables for the second born initial child
  ifelse color = red
    [ set social-class red ]
    [ ifelse color = green
     [set social-class green]
     [set social-class blue]
    ]
  set adult false
  set age random (16)                              ; second born child can be 0 to 16 years old
  face one-of neighbors4
  ifelse (random-float 1.0 < 0.5)
   [set sex "M"]
    [set sex "F"]
  set married false
  set partner-ID 0
  set child-count 0
  set partner-ID 0
  set child-ID-I 0
  set child-ID-II 0
  set partner-alive false
  set color white
  set wealth 1
  ask turtles with [family-ID = [family-ID] of myself]   ; the new born has to save its ID in the variables of parents, that they can find it on the field
    [set child-ID-II [who] of myself]
end

;;;
;;; GO AND HELPERS
;;;

;; the "to go" function is triggers the main commands and subfunctions which are necessary for each tick,
;; i.e. moving to the best patch, harvest the patch, spread out to an empty patch, consume + age + die, recoloring functions, immigration and updating different indicators
to go
  ask turtles
    [ turn-towards-utility]           ; choose direction holding most utility within the turtle's vision
  harvest                             ; turtles harvest the utility off the field they moved to
  ask turtles
  [ let empty-patches neighbors with [not any? turtles-here] ; this ensures only one turtle per patch
    if any? empty-patches
      [ let target one-of empty-patches
        face target
        move-to target
      ]
  ]
  ask turtles
   [ eat-age-die ]
  recolor-turtles
  if ticks mod utility-growth-interval = 0                   ; grow utility every utility-growth-interval clock ticks
    [ ask patches [ grow-utility ] ]

  conduct-immigration                                        ; new turtles get added through an immigration procedure
  recolor-turtles                                            ; turtles get recolored depending on their current wealth
  update-utility-counter                                     ; total utility in the system gets recorded
  update-lorenz-and-gini                                     ; lorenz curve and gini coefficient get updated
  update-inflation                                           ; total inflation counter gets recorded (comparing current utility with utility after setup)
  update-inheritance-tax-allowance-absolute                  ; current allowance on inheritance tax gets updated

  tick
end

;; determine the direction which is most profitable for each turtle in
;; the surrounding patches within the turtles' vision
;; turtles then move to this respective patch
to turn-towards-utility
   set heading 0
     let best-direction 0
     let best-amount utility-ahead
     let best-patch best-patch-ahead

   set heading 90
   if (utility-ahead > best-amount)
     [ set best-direction 90
       set best-amount utility-ahead
       set best-patch best-patch-ahead]

   set heading 180
   if (utility-ahead > best-amount)
     [ set best-direction 180
       set best-amount utility-ahead
       set best-patch best-patch-ahead ]

   set heading 270
   if (utility-ahead > best-amount)
     [ set best-direction 270
       set best-amount utility-ahead
       set best-patch best-patch-ahead]

   set heading best-direction

   move-to best-patch                     ; turtles move to the best patch they identified within their vision

end

;; a reporting function which reports the utility of a particular direction within a turtle's vision
;; depending on this function, the best direction is chosen
to-report utility-ahead
  let best-amount 0
  let how-far 1
  let best-patch 0
  repeat vision
  [
      if ([utility-here] of patch-ahead how-far >= best-amount)
      [
          set  best-amount [utility-here] of patch-ahead how-far
          set  best-patch patch-ahead how-far
      ]
      set how-far how-far + 1
  ]
  report best-amount
end

;; a reporting function which reports the best patch ahead of a particular direction within a turtle's vision
;; depending on this function, the turtle moves to the best patch
to-report best-patch-ahead
  let best-amount 0
  let how-far 1
  let best-patch 0
  repeat vision
  [
      if ([utility-here] of patch-ahead how-far >= best-amount)
      [
          set  best-amount [utility-here] of patch-ahead how-far
          set  best-patch patch-ahead how-far
      ]
      set how-far how-far + 1
  ]
  report best-patch
end

;; patch procedure
;; add num-utility-grown to a certain portion of all patches
to grow-utility
  let chance-to-grow-utility random 100
  if chance-to-grow-utility < utility-growth-chance-per-patch
  [
      set utility-here utility-here + num-utility-grown
  ]
  recolor-patch                                   ; patches get recolored according to the amount of utility they are now holding
end

;; each turtle harvests the utility on its patch.
to harvest
  ;; have turtles harvest before any turtle sets the utility on the patch to 0
  ask patches
  [
      ask turtles-here with [adult = true]                  ; only adult turtles harvest utility
      [
         set wealth floor (wealth + (utility-here))         ; it is ignored if there are more than one turtles on a field. Dividing the utility would lead to a disadvantage to turtles with a higher vision (unfavorable)
         if color = blue
           [ wealth-taxing ]                                ; blue turtles can get taxed on their income (for current simulation this is fixed to 0)
       ]

  ;; now that the utility has been harvested, have the turtles make the patches which they are on have no utility
      ask turtles-here with [adult = true]
      [
          set utility-here 0
          recolor-patch
      ]
  ]
end

;; conduct the wealth taxation. The wealth tax has been set to 0 for this simulation)
to wealth-taxing                                         ; turtles where the inheritance amount is higher than the allowance, put the tax on their income back on a few random patches
  let tax (utility-here * (wealth-taxation / 100 ))
  set wealth (wealth - tax)
      ; add-wealth-tax
   repeat round (tax / 5)                                ; tax gets spread on random patches in stacks of 5
   [
     ask one-of patches
      [set utility-here (utility-here + 5)
      ]
   ]
end

;; standard procedures necessary to simulate the life of the agents like consumption, ageing and dieing
;; this function is triggered at each tick for each turtle (ask)
to eat-age-die
  set wealth (wealth - consumption)            ; turtles consume some of their wealth
  feed-children                                ; adult turtles "feed" their children by giving them some utility
  if child-count > 1                           ; parents keep track of their children's age
  [set child-age (child-age + 1)]
  if wealth <= 0                               ; wealth can not become less than 0
  [set wealth  0]
  set age (age + 1)                            ; turtles grow older
  if age >= 18                                 ; turtles become adults once they reach the age of 18
  [set adult true]
  let median-wealth median [wealth] of turtles
 ifelse married = true                         ; a turtle has to reproduce if married otherwise marry
  [reproduce]
  [marry]
  ifelse color = red and age > life-expectancy-low              ; check for death conditions:  if a turtle is older than the average life expectancy for his social class
  [inherit                                     ; when turtles die, their partner or their children inherit their wealth
   partner-dies
   die ]
  [ifelse color = green and age > life-expectancy-middle
   [inherit
    partner-dies
    die ]
    [if color = blue and age > life-expectancy-high
      [inherit
        partner-dies
        die
      ]
    ]
  ]
end

;; Parents feed their children by giving them some utility (pocket money etc.). Rich turtles get more than poorer ones.
;; the value with which the children are fed, rises with the inflation-factor
to feed-children
  if (adult = true and child-count >= 1 and child-age <= 18)
  [ifelse color = red
    [ set wealth (wealth - floor (feed-low * inflation-factor)) ]      ; pocket money scales with inflation
    [ ifelse color = green
     [set wealth (wealth - floor (feed-middle * inflation-factor))]
     [set wealth (wealth - floor (feed-high * inflation-factor))]
    ]
  ]

  if (adult = false)                                                   ; Children receive their pocket money
  [ifelse social-class = red
    [ set wealth (wealth + floor (feed-low * inflation-factor)) ]
    [ ifelse social-class = green
     [set wealth (wealth + floor (feed-middle * inflation-factor))]
     [set wealth (wealth + floor (feed-high * inflation-factor))]
    ]
  ]

end

;; all male, unmarried turtles get the chance to look for potential partners
;; first, there is a check if there are still potential partners available (within their age range) on the field
;; if there are, one gets chosen randomly and they marry with a certain chance (chance-to-marry), depending on their social class
to marry
  let marriage random 100
  let match false
  let marry-ID 0
  if adult = true and sex = "M" and count turtles with [sex = "F" and adult = true and married = false and age <= ([age] of myself + 15) and age >= ([age] of myself - 15)] > 1
  [ask one-of turtles with [adult = true and sex = "F" and married = false and family-ID != [family-ID] of myself and age <= ([age] of myself + 15) and age >= ([age] of myself - 15)]
     [ifelse color != [color] of myself and
       marriage <= (chance-to-marry / 3)
       [set married  true
        set match true
        set partner-alive true
        set family (family + 1)
        set family-ID family * 2 + 1
        set partner-ID [who] of myself           ; a turtle save the own ID at a partners variable to find him/her on the field
        set marry-ID who
      ]
      [if color = [color] of myself
      [ if marriage  <= chance-to-marry
        [set married  true
         set match true
         set partner-alive true
         set family (family + 1)
         set family-ID family * 2 + 1
         set partner-ID [who] of myself          ; a turtle save the own ID at a partners variable to find him/her on the field
         set marry-ID who
        ]
       ]
      ]
     ]
    if match = true
    [ set married true                           ; the male turtle also registers as married from now on
      set family-ID family * 2 + 1
      set partner-ID (marry-ID)
      set partner-alive true
   ]]


end

;; female turtles reproduce when married and get 2 children
to reproduce
  if sex = "F" and child-count < 2 and
     age >= minimum-age-to-reproduce and age <= maximum-age-to-reproduce
       [hatch 1 [set-child-vars-I]
        set child-count (child-count + 1)
       hatch 1 [set-child-vars-II]
        set child-count (child-count + 1)
        set child-age 0
    ask turtles with [who = partner-ID]           ; the male turtles (partners) set their child-count to two as well
    [set child-count 2
    set child-age 0]
  ]
end

; set the starting variables for the first born child
; the child's social class gets determined at birth, which influences the amount of pocket money they will receive
to set-child-vars-I
  ifelse color = red
    [ set social-class red ]
    [ ifelse color = green
     [set social-class green]
     [set social-class blue]
    ]
  set age  1
  set adult false
  face one-of neighbors4
  ifelse (random-float 1.0 <= 0.5)
   [set sex "M"]
    [set sex "F"]
  set married false
  set child-count 0
  set partner-ID 0
  set child-ID-I 0
  set child-ID-II 0
  set partner-alive false
  set color white                                       ; children are recognizable by their white color
  set wealth 1
  ask turtles with [family-ID = [family-ID] of myself]  ; the new born has to save its ID in the variables of parents, that they can find it on the field
    [set child-ID-I [who] of myself]
end

; set the starting variables for the second born child
; the child's social class gets determined at birth, which influences the amount of pocket money they will receive
to set-child-vars-II
  ifelse color = red
    [ set social-class red ]
    [ ifelse color = green
     [set social-class green]
     [set social-class blue]
    ]
  set age  1
  set adult false
  face one-of neighbors4
  ifelse (random-float 1.0 <= 0.5)
   [set sex "M"]
    [set sex "F"]
  set married false
  set partner-ID 0
  set child-count 0
  set partner-ID 0
  set child-ID-I 0
  set child-ID-II 0
  set partner-alive false
  set color white
  set wealth 1
  ask turtles with [family-ID = [family-ID] of myself]   ; the new born has to save its ID in the variables of parents, that they can find it on the field
    [set child-ID-II [who] of myself]
end

;; When a a turtle dies it inherits its wealth to their partner
;; If their partner is not alive anymore, their children receive their wealth
;; If they die without ever having children, 4 random "distant relatives" of the same social class are found who inherit their wealth
;; Inheritance tax has to be paid
to inherit
  let inheritance-tax-money (([wealth] of self - inheritance-tax-allowance-absolute) * (Inheritance-Tax / 100))   ; inheritance-tax-money is the amount of inheritance tax being paid

  if inheritance-tax-money < 0 ; inheritance money can't be negative
  [set inheritance-tax-money 0]


  let inheritance ([wealth] of self - inheritance-tax-money)

  ifelse partner-alive = true                             ; when a turtle dies, its money will be inherited - If alive, the married partner will be first in inheritance order
    [ask turtles with [who = [partner-ID] of myself]
       [set wealth (wealth + inheritance)]
  ]

    [ifelse child-count = 2
       [ask turtles with [ who = [child-ID-I] of myself]
          [set wealth (wealth + (inheritance / 2))        ; in case the partner died before, the children inherit the wealth
          ]
        ask turtles with [ who = [child-ID-II] of myself] ; each child get the half of the parents money minus the selected amount of inheritance tax
          [set wealth (wealth + (inheritance / 2))
          ]
    ]
       [ifelse child-count = 1
          [ask turtles with [ who = [child-ID-I] of myself]
             [set wealth (wealth + inheritance)           ; in case the partner died before, the children inherit the wealth
             ]
      ]

       [repeat 4
        [ask one-of turtles with [age <= maximum-age-distant-relative and color = [color] of myself]
          [set wealth (wealth + (inheritance / 4))
          ]
       ]
      ]
       ]
    ]

  repeat round (inheritance-tax-money / 5)                ; the inheritance tax collected gets distributed randomly along the field in stacks of 5
   [
     ask one-of patches
      [set utility-here (utility-here + 5)]
   ]
end

; if the partner of a turtle dies, the other partner needs to know in terms of inheritance
; if a partner dies, the family counter goes down as the couple is no longer married
to partner-dies
    ask turtles with [ who = [partner-ID] of myself]
    [ set partner-alive false]
end

; this function updates the utility counter to have an idea of how much utility is in the system
; every tick, the total amount of utility on patches and in agents' possession gets counted
to update-utility-counter
  set utility-counter 0
  ask patches
  [set utility-counter (utility-counter + utility-here)
  ]
  ask turtles
  [set utility-counter (utility-counter + wealth)
  ]
end

;; this procedure recomputes the value of gini-index-reserve
;; and the points in lorenz-points for the Lorenz and Gini-Index plots
to update-lorenz-and-gini
  let sorted-wealths sort [wealth] of turtles
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  set gini-index-reserve 0
  set lorenz-points []

  ;; now actually plot the Lorenz curve -- along the way, we also
  ;; calculate the Gini index.
  ;; (see the Info tab for a description of the curve and measure)
  repeat count turtles [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-index-reserve
      gini-index-reserve +
      (index / count turtles) -
      (wealth-sum-so-far / total-wealth)
  ]
end

;; updates the inflation factor, comparing the current amount of utility in the system with the amount after setup
to update-inflation
  set inflation-factor (utility-counter / starting-utility)
end

;; the population gets increased due to immigration
to conduct-immigration
  set immigration-number-people ((count turtles) * immigration-rate / 100)

  create-turtles immigration-number-people * initial-percentage-higher-class
    [ move-to one-of patches
      set size 1.0
      set-initial-turtle-vars-low ]
  create-turtles immigration-number-people * initial-percentage-middle-class
    [ move-to one-of patches
      set size 1.0
      set-initial-turtle-vars-middle ]
   create-turtles immigration-number-people * initial-percentage-lower-class
    [ move-to one-of patches
      set size 1.0
      set-initial-turtle-vars-high ]
recolor-turtles
end

;; this procedure recomputes the value of the absolute number of the	tax-exempt amount
;; and the points in lorenz-points for the Lorenz and Gini-Index plots
to   update-inheritance-tax-allowance-absolute

  set inheritance-tax-allowance-absolute (mean [wealth] of turtles * inheritance-tax-allowance / 100)

end

; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
193
10
687
505
-1
-1
6.0
1
10
1
1
1
0
1
1
1
-40
40
-40
40
1
1
1
ticks
30.0

BUTTON
8
181
84
214
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
101
182
171
215
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
3
12
186
45
num-adult-people
num-adult-people
50
800
500.0
1
1
NIL
HORIZONTAL

SLIDER
4
235
185
268
percent-best-land
percent-best-land
5
100
8.0
0.5
1
%
HORIZONTAL

PLOT
4
511
256
691
Class Plot
Time
Turtles
0.0
50.0
0.0
100.0
true
true
"set-plot-y-range 0 100\n" ""
PENS
"low" 1.0 0 -2674135 true "" "plot count turtles with [color = red] / count turtles * 100"
"mid" 1.0 0 -10899396 true "" "plot count turtles with [color = green] / count turtles * 100"
"up" 1.0 0 -13345367 true "" "plot count turtles with [color = blue] / count turtles * 100"

SLIDER
4
308
184
341
num-utility-grown
num-utility-grown
0
20
8.0
1
1
NIL
HORIZONTAL

PLOT
258
511
470
691
Class Histogram
Classes
Turtles
0.0
3.0
0.0
100.0
true
false
"set-plot-y-range 0 100" ""
PENS
"default" 1.0 1 -2674135 true "" "plot-pen-reset\nset-plot-pen-color red\nplot count turtles with [color = red] / count turtles * 100\nset-plot-pen-color green\nplot count turtles with [color = green] / count turtles * 100\nset-plot-pen-color blue\nplot count turtles with [color = blue] / count turtles * 100"

PLOT
472
511
686
691
Lorenz Curve
Pop %
Wealth %
0.0
100.0
0.0
100.0
false
true
"" ""
PENS
"equal" 100.0 0 -16777216 true "plot 0\nplot 100" ""
"Lorenz" 1.0 0 -10873583 true "" "plot-pen-reset\nset-plot-pen-interval 100 / count turtles\nplot 0\nforeach lorenz-points plot"

PLOT
693
510
900
690
Gini-Index v. Time
Time
Gini
0.0
50.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot (gini-index-reserve / count turtles) / 0.5"

PLOT
692
168
895
294
Median-Wealth
Time
Median-Wealth
0.0
250.0
0.0
150.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot median [wealth] of turtles"

PLOT
692
305
895
446
Mean of Age
Time
Age
0.0
100.0
18.0
85.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [age] of turtles"

PLOT
692
10
1099
160
histogramm
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"total" 1.0 0 -16777216 true "" "plot count turtles"
"children" 1.0 0 -7500403 true "" "plot count turtles with [adult = false]"

MONITOR
693
459
898
504
NIL
family
17
1
11

SLIDER
3
51
187
84
Inheritance-Tax
Inheritance-Tax
0
70
70.0
1
1
%
HORIZONTAL

SLIDER
4
271
184
304
utility-growth-interval
utility-growth-interval
0
10
1.0
1
1
NIL
HORIZONTAL

PLOT
1113
10
1313
160
Immigration
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot immigration-number-people"

SLIDER
4
401
184
434
immigration-rate
immigration-rate
0
0.5
0.35
0.05
1
NIL
HORIZONTAL

PLOT
904
167
1104
294
Total Utility
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "plot utility-counter" "plot utility-counter"

SLIDER
2
88
188
121
inheritance-tax-allowance
inheritance-tax-allowance
0
300
75.0
5
1
%
HORIZONTAL

PLOT
905
306
1105
444
Marital Status
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"married" 1.0 0 -16777216 true "" "plot (count turtles with [married = true and adult = true] / count turtles with [adult = true]) * 100"
"unmarried" 1.0 0 -7500403 true "" "plot (count turtles with [married = false and adult = true] / count turtles with [adult = true]) * 100"

PLOT
1113
165
1313
294
male/ female
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"female" 1.0 0 -2674135 true "" "plot (count turtles with [sex = \"F\"] / count turtles) * 100"
"male" 1.0 0 -13791810 true "" "plot (count turtles with [sex = \"M\"] / count turtles) * 100"

SLIDER
4
455
183
488
chance-to-marry
chance-to-marry
0
100
15.0
5
1
%
HORIZONTAL

PLOT
1114
304
1314
443
inflation factor
NIL
NIL
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot inflation-factor"

SLIDER
4
344
185
377
utility-growth-chance-per-patch
utility-growth-chance-per-patch
0
30
12.0
1
1
%
HORIZONTAL

PLOT
910
457
1316
689
Median Wealth of turtle in social class
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"low" 1.0 0 -2674135 true "" "plot median [wealth] of turtles with [color = red]"
"mid" 1.0 0 -10899396 true "" "plot median [wealth] of turtles with [color = green]"
"up" 1.0 0 -13345367 true "" "plot median [wealth] of turtles with [color = blue]"

@#$#@#$#@
## ODD-protocol

In the following, the model is described in detail. For a sufficient understanding of how the model works, the subsequent structure is following the procedure of the ODD protocol (Grimm et al., 2010).
Purpose of the model
This ABM aims to show the influence of inheritance taxation on the distribution of wealth in a society. Explicitly, this means to take a look at how strong the influence of inheritance taxation on the so-called GINI-Index is, which is “the most widely used measure for studying social, economic and health inequality” within a society (Liao, 2006). Ultimately, the data provided by the model should ideally give indications for policy makers if and to what extend inheritance taxation can be helpful and should be implemented.

## Entities, state variables and scales
The actors in the simulation model are the agents (in Netlogo they are called ‘turtles’), which are living and moving on a rectangular landscape on a grid. These agents represent people, while all agents as a whole represent a society. The grid can therefore represent for instance a whole country.
Agents are distinguishable from one another by several state variables: Their turtle ID, Age, wealth, consumption, vision, sex, adult or child, married or single, their family-ID, child count, child age, if their partner is alive, their partner’s ID, their children’s ID , their social class and their location on the grid.
These agents interact with each other, but also with their environment, represented by a grid of patches. Patches are only distinguishable from one another by their respective geographical position within the grid and the amount of utility they are holding.

While most parameters are self-explicatory, a few may need elaborations. Utility is the simulation’s currency, representing money, assets or wealth in general. IDs are distinct numbers the agents get assigned by Netlogo on creation. Therefore an agent saves his own ID, as well as their partner’s ID when they get married and their children’s respective IDs when they are being born. The parameter ‘wealth’ counts the amount of utility an agent is holding at the moment. ‘Consumption’ on the other hand is the amount of said utility each individual agent is using, or consuming (and therefore subtracting from their wealth) with each tick. A ‘tick’ is the time unit within the model representing one year in reality.
‘Vision’ is a concept that is supposed to give some agents better chances at collecting utility from the patches around them than others. With each tick, agents are scanning their surrounding patches in order to identify the one that is holding the highest amount of utility. A higher vision allows agents to look and subsequently move further to afterwards collect that utility (e.g. a vision of 2 allows turtles to look and move 2 patches ahead). The social class is a concept that distinguishes agents by their wealth and categorizes them as either belonging to the lower (represented in the model by the color red), middle (green) or upper class (blue) of the society. If an agent holds less than a third the wealth of the ‘richest’ agent, it gets colored red. If it’s between one and two thirds, it gets colored green, or else it gets colored blue. Agents in the child-age (< 19 years) inherit their parents’ social class at birth but are colored white. 

## Process overview and scheduling

In the setup process, first all global variables get fixed and the patches get set up (to setup-patches). Here, some starting utility gets created, spread around on the grid and assigned to some of the patches. After the patch setup, the turtles get created (to setup-turtles). Afterwards, the Lorenz curve and Gini-coefficient-plot as the utility counter monitoring plots get set up (to update-lorenz-and-gini, to update-utility-counter).

The general procedure that the model follows each tick starts with the turtles looking for and moving to the patches holding the highest utility (to turn-towards-utility). Afterwards, the turtles harvest the utility of the patches they are standing on (to harvest). In order to avoid more than one turtle staying on the same patch, they are then forced to move to an empty patch. After that, the turtles do everything else their life requires of them (to eat-age-die). They consume utility, they feed their children (to feed-children) and keep track of their children’s age. They age and get classified as adults once they reach the age of 18, they marry (to-marry) and reproduce. If they have reached their life expectancy the inheritance process (to inherit) gets triggered and their partners get notified (to partner-dies). Then the turtles die.
Afterwards, the immigration process is being conducted (to conduct-immigration), the turtles get recolored according to their respective wealth (to recolor-turtles) and some more utility is grown on the patches (to grow-utility). Then, several counters and plots get updated (to update-utility-counter, to update-lorenz-and-gini, to update-inflation, to update-inheritance-tax-allowance-absolute). Ultimately times moves on another tick (or year).

## Design Concepts

The aim of the agents in this simulation is simply to maximize their own wealth, which can be acquired by collecting utility from the patches. 
With the start of the simulation each agent moves around the grid in the direction of the patch with the most utility and collects it when the agent steps onto the particular patch. Over time, utility gets created and randomly distributed along the grid for the agents to pick up. Some of the utility collected is consumed and some handed down to their children.
While interacting with other agents of the opposite gender, there is a chance that they will marry and get children in the rounds to come, considering they are of the right age.
When a turtle reaches the end of its lifespan, he or she dies, bequeathing their remaining wealth to their next of kin, meaning their spouse or their children. This is where inheritance taxation comes into play, meaning that a certain percentage of said bequest will be deducted and randomly distributed on the grid again.
The following basic principles are at work in the model:
At the center of this model lies the principle of the agents earning and accumulating wealth over their lifespan. For this matter, the very complex real-life mechanisms of wealth accumulation, labor earnings, interest gains and so on are being reduced to the relatively simple motivations and mechanisms of agent wealth accumulation described above. In order to reflect the unequal opportunities people from different social classes are facing in these processes, different abilities to earn money based on their wealth or inheritance from their parents are implemented into the model. At the center of the model is the vision each agent has, favoring those with higher range to find better patches, holding more utility, on the grid. This principle by itself creates unequal opportunities for the agents simply because of their social status, representing for instance higher incomes and more investment opportunities for people holding more wealth. Children are subjective to this, too. While they only start collecting utility on their own once they reach adulthood (the age of 18), the amount of utility they get fed and supported with by their parents also depends on the social class they were born into. This represents for instance better education and better nourishment children of higher social classes often receive.
Objectives:
The agents’ objective is simply to increase their own wealth, i.e. collect utility. This serves as a representation for most people’s objective to better their living situation and social status. Other possible objectives are secondary for this matter and therefore not included in the model.
Adaptation:
The agents in this model are not designed to act particularly adaptive. Instead, they are designed to reproduce observed behavior. This can be seen in factors such as the percentile chance to marry when agents encounter each other, where stochasticity plays the biggest role. The focus of this model is not on the internal processes at play, but rather on the results of a few key indicators such as the GINI index. In order to keep the model simple, agents are also not able to develop their own strategies to accumulate wealth. They are all forced to follow the same routine of chasing the next-best patch. 
Interaction:
The agents mostly face a form of indirect interaction with each other. Because every agent has the same objective of collecting utility and maximizing their wealth fighting for scarce resources, competition is at the center of the model. However, agents only truly interact when they marry and have children. With its offspring, an agent interacts in the sense that they pay for their living expenses by passing down some of their wealth with each tick, until the children reach adulthood. Inter-agent social consequences from this competition for resources and societal wealth distribution are not supposed to be part of the model and are therefore left to the imagination of the model’s interpreter.
Collectives:
Based on the wealth they are holding compared to the median of the whole society, the agents get assigned to a social class (lower, middle or upper class). Their social class changes their behavior in terms of their consumption and allows them to collect utility more effectively. It also determines the chances of which other agents they marry (favoring those of the same social class) and the financial support they give to their offspring.
Stochasticity:
Some factors included in the model are dependent on stochasticity. This includes the amounts of utility created and its distribution and the set-up parameters for the agents. Some stochasticity is at play in agent actions such as the chance to marry while encountering other agents and the chance to reproduce.
Observation:
Ultimately, while passing a certain amount of ticks and the society goes through several generations of agents, the development of the GINI index can be observed as well as the size of the different classes, namely the lower middle and upper class. Then, based on the input factors (e.g. the level of inheritance taxation implemented in the respective simulation run), deductions about its correlation with the GINI index can be made.

## Initialization

The initial setup of the population is, where possible, based on statistical data about industrialized societies such as the population of Germany. The agents’ life expectancy has been fixed to 79, which equals today’s average life expectancy for men and women in industrialized societies (Statista, 2019d).
When it comes to the birth rate at which agents reproduce, the decision not to particularly match the actual birth rate in Germany or other comparable countries was taken. Instead, the focus lied on keeping the population under control, meaning to prevent it from growing or declining drastically. This was achieved by granting each married couple two children but restricting the chance to find a partner and marry to 90%, or 30% depending on the fact if the turtles are from the same social class or not. Additionally, immigration was taken into account to prevent the population from going extinct. To get an idea of the value of net-immigration to Germany, the data of immigration (Statista, 2019b) and emigration (Statista, 2019c) was compared with the population of Germany (Statistisches Bundesamt, 2019c). This leads to an average yearly net-immigration of around 0,35% compared with the whole population, which was implemented into the model.
In the setup process, 19% of the turtles initially get assigned to the higher class, 58% get assigned to the middle class and 23% to the lower class. This correlates with social class distributions in Germany, where people are considered a part of the lower social class if their income is lower than 70% of the median income and part of the higher class if their income is higher than 150% of the median income (Statista, 2019e) (Niehues, J., 2017). Therefore, agents in the model get reassigned to their respective social classes according to these ratios as well when they accumulate and lose wealth as time passes.
The initial wealth each agent is starting with also depends on their social class. According to studies, the richest 20% in Germany hold approximately two thirds of the total wealth. The poorest 20% hold basically nothing and are on average slightly indebted (Davies et al., 2008, p.4). This was translated into the model in the sense that higher-class turtles start with 200 utility, middle-class turtles start with 99 utility and lower-class turtles start with just 1 utility, as the model is not designed to allow debt. This fact correlates with the assumption that people in Germany receive social welfare if they cannot pay for their living expenses themselves (agents in the model can at no point fall below 1 wealth).
Agent consumption was set to 1/2/4 utility per tick depending on the social class (consumption-low /consumption-middle/ consumption-high) after an approximation to German census results that accounted household net spending on consumption ranging from 1025€ to 4479€ per person (mean: 2480€), depending on personal income (Statistisches Bundesamt, 2018, p.181). As a simplification, the same ratios (1/2/4 utility per tick) were applied to the amount parent agents give to their children as support (feed-low/ feed-middle/ feed-high).
At this point, a note on the Gini coefficient deems necessary. While the Gini coefficient is not a factor that gets manually set at the beginning of the simulation, it results from factoring decisions such as those mentioned above. Notably, the coefficient in the model after setup doesn’t quite match the actual Gini coefficient in Germany which is at 0.667 (Davies et al., 2008), even though most factors where matched to the German society. However, there are a few simplifications within the model that result in the Gini coefficient being lower after setup. Most notably would be the absence of extreme values in wealth. Plainly said, there are no billionaire turtles existing in the model yet, as well as no turtles that are deeply indebted. Especially the top 1% of wealth holders are usually responsible for driving inequality measurements through the roof.

Other starting coefficient values were mostly set the way they were deemed realistically, or result from careful considerations and sensitivity analyses (see Appendix 2) and can be seen in Table 4.

Table 5: Model initialization values for independent and control variables. Sometimes depending on the agent's social class (lower/middle/higher)
Independent Variables	Value(s)	Control Variables	Value(s)
Inheritance tax [%]	0/25/50/70	Number of ticks per simulation	250
Inheritance tax allowance [%]	0/100/200/300	Number of adult agents at setup	500
		Agent life expectancy	79
		Agent setup wealth (l/m/h) [utility]	1/99/200
		Wealth tax [%]	0
		Min./ Max. age to reproduce [years]	18/50
		Percentile share of social classes at setup (l/m/h) [%]	23/58/19
		Max. agent age to count as ‘distant relative’ [years]	55
		Agent chance to marry (same social class/ not) [%]	15/5
		Age-range for marriage [years]	+- 15
		Agents’ vision (to find utility) (l/m/h) [patches]	1/2/4
		Agent feed of children [utility]	1/2/4
		Immigration rate [%]	0.35
		Agent consumption [utility]	1/2/4
		Max utility per patch at setup [utility]	50
		Percentile share of patches that receive most utility at setup [%]	8
		Utility growth interval [ticks]	1
		Amount of utility grown per patch [utility]	8
		Utility growth chance per patch [%]	12

## Submodels

In the following, the submodels mentioned above are described. Not every function implemented in the whole model is listed here, as some are self-explicatory and can be easily comprehended when viewing the code. However, some submodels are crucial to understand and therefore listed below.
to turn-towards-utility (to-report utility-ahead, to-report best-patch-ahead):
In this function, the whole utility-finding- and movement-process is undertaken. In order to find the best patches, the turtles turn around on their axis and save the direction in which the most promising patch is lying. This is realized by the functions ‘to-report utility ahead’ and ‘to-report best-patch-ahead’, where the turtle saves the highest amount of utility it can see within its vision range in the variable ‘best-amount’ and the respective patch in the variable ‘best-patch’. While checking all directions and all patches it can see within its vision, these variables get updated once the turtle sees a more promising field. Ultimately, the ‘best-direction’ has been identified and the turtle moves to the ‘best-patch’.
Turtles that are still children (<18 years old) however skip this whole process and move randomly along the grid. They also don’t harvest any utility.

to harvest:
In this function, the turtles pick up all of the utility of the patch they just moved to by first raising their wealth by the amount the patch is holding and then setting the patches’ utility to zero. If more than one turtle lands one the same patch, both receive the full amount of utility. This is an inaccuracy in the model’s logic, but it was deemed more important that turtles get the full harvest off of their class advantage. This is to avoid that especially ‘richer’ turtles would have to share more often than lower-class turtles as they are able to travel further to utility-rich patches.
to feed children:
Parents give their children some of their wealth each tick to pay for their living expenses, tuition and so on. In this function, first each of the parents’ utility gets deducted from their wealth by a certain amount and then both of their children receive said amount added to their own wealth. The amount depends on the social class and this process takes place until the children are 18 years old.
to marry:
In order to give turtles the opportunity to marry, the ‘to marry’ function gets activated each tick for single, male turtles. They randomly get a possible female partner assigned that is unmarried, not related to them and falls within a certain age range (±15 years of their own age). Then, with a certain ‘chance-to-marry’, they will get married or not (the chance to marry is three times as high if both turtles are from the same social class). If they get married, both newlywed partners save their new partner’s ID and register as married from now on until their death.
to reproduce (to set-child-vars-I, to set-child-vars-II):
Female turtles that recently got married will now get two children, if they are below the ‘maximum-age-to-reproduce’. Once these children are created, the female turtle and its partner save their children’s ID. The newly born children at the same time save their parents’ ID. In ‘to set-child-vars-I’ and ‘to-set-child-vars-II’ these children also inherit all of their mother’s variables but get most of them set to zero (such as their wealth). They will however receive their mother’s social class and position on the grid.
Setup process (to set-initial-relationships, to set-initial-children:
During the setup process some turtles already get married (to set-initial-relationships). This function works in the same way as described above (to marry) with the only difference, that the initial chance to marry is set to 90% and 30% respectively in order to quickly create turtle families. Afterwards, children get created in the setup process as well (to set-initial-children). This function works the same as described above (to reproduce) with the exception, that here the children created with a random age between 0 and 17 for the first and 0 and 16 for the second one.
to inherit (to partner-dies):
When turtles have reached their maximum age they die and bequeath their wealth to their spouse. In this function, first the amount of inheritance tax that needs to be paid gets calculated and subtracted. The remaining wealth then gets transferred to their partner. If their partner is not alive anymore, which is set in the function ‘to partner-dies’, both children receive half of the inherited wealth. If turtles die without ever receiving children the turtle’s wealth gets bequeathed to 4 randomly selected turtles below a certain age (‘maximum-age-distant-relative’), which serve as distant relatives that usually get found somewhere in people’s family trees.
The deducted inheritance tax gets randomly distributed in stacks of 5 utility on the grid again for other turtles to pick up.
to conduct-immigration:
The immigration rate gets set in the setup process, but the actual number of turtles immigrating onto the grid gets calculated each tick. These agents are set somewhere randomly onto different patches, get assigned to one of the three social classes and receive starting wealth just like the other turtles earlier in the setup process.
to update-inflation:
Each tick, a so-called ‘inflation-factor’ gets computed. It compares the amount of utility within the whole system (lying around on patches or in turtle’s possession) with the amount at the start of the simulation. The amount of utility usually rises in the simulation, mostly because more and more wealth gets created with each tick. This represents economic growth on one hand and actual inflation on the other. This ‘inflation-factor’ then influences several factors within the model. The agents’ consumption, the amount they feed to their children and the immigrated agents’ starting wealth all scale with this inflation factor, in order to keep them relevant as the utility in the system rises. 

## References

For references and more detailed data see the corresponding paper bei Lutz & Teckentrup (2019)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles</metric>
    <metric>count gini-index-reserve</metric>
    <steppedValueSet variable="num-grain-grown" first="2" step="2" last="10"/>
    <steppedValueSet variable="metabolism-max" first="5" step="5" last="60"/>
    <steppedValueSet variable="grain-growth-interval" first="2" step="2" last="10"/>
    <enumeratedValueSet variable="Basic-Income">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="percent-best-land" first="2.5" step="2.5" last="25"/>
    <enumeratedValueSet variable="Wealth-Taxation">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="100"/>
      <value value="10"/>
      <value value="600"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count "gini-index-reserve"</metric>
    <steppedValueSet variable="num-grain-grown" first="2" step="2" last="10"/>
    <enumeratedValueSet variable="metabolism-max">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="grain-growth-interval" first="2" step="2" last="10"/>
    <enumeratedValueSet variable="percent-best-land">
      <value value="21.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wealth-Taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = green]</metric>
    <steppedValueSet variable="num-grain-grown" first="2" step="2" last="10"/>
    <enumeratedValueSet variable="metabolism-max">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="grain-growth-interval" first="2" step="2" last="10"/>
    <steppedValueSet variable="percent-best-land" first="5" step="5" last="25"/>
    <enumeratedValueSet variable="Wealth-Taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>gini-index-reserve</metric>
    <enumeratedValueSet variable="num-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grain-growth-interval">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="21"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Wealth-Taxation" first="0" step="50" last="50"/>
    <steppedValueSet variable="Inheritance-Tax" first="0" step="50" last="50"/>
    <enumeratedValueSet variable="num-grain-grown">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Repetitions" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>gini-index-reserve</metric>
    <enumeratedValueSet variable="num-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grain-growth-interval">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wealth-Taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-grain-grown">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Wealth-Taxation10%" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>gini-index-reserve</metric>
    <enumeratedValueSet variable="num-grain-grown">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grain-growth-interval">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wealth-Taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Wealth-Taxation0%Inherit30%" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="num-grain-grown">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grain-growth-interval">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Wealth-Taxation" first="50" step="5" last="70"/>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="PeopleAnalysis" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="num-grain-grown">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grain-growth-interval">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wealth-Taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_1_20runs" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <metric>count turtles</metric>
    <metric>count turtles with [adult = false]</metric>
    <metric>utility-counter</metric>
    <metric>inflation-factor</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_2_10runs_chancetomarry" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_3_10runs_utility" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>inflation-factor</metric>
    <metric>utility-counter</metric>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <metric>count turtles with [color = red] / count turtles * 100</metric>
    <metric>count turtles with [color = green] / count turtles * 100</metric>
    <metric>count turtles with [color = blue] / count turtles * 100</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_4_10runs_vision" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>inflation-factor</metric>
    <metric>utility-counter</metric>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <metric>count turtles with [color = red] / count turtles * 100</metric>
    <metric>count turtles with [color = green] / count turtles * 100</metric>
    <metric>count turtles with [color = blue] / count turtles * 100</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-taxation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_5_10runs_Vision" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>inflation-factor</metric>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <metric>median [wealth] of turtles with [color = red]</metric>
    <metric>median [wealth] of turtles with [color = green]</metric>
    <metric>median [wealth] of turtles with [color = blue]</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-low">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-middle">
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-high">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_5_10runs_Vision" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>inflation-factor</metric>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <metric>median [wealth] of turtles with [color = red]</metric>
    <metric>median [wealth] of turtles with [color = green]</metric>
    <metric>median [wealth] of turtles with [color = blue]</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-low">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-middle">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-high">
      <value value="1"/>
      <value value="3"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_CoefficientVariation_10" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_CoefficientVariation_50" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_CoefficientVariation_100" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_CoefficientVariation_200" repetitions="200" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_CoefficientVariation_500" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_CoefficientVariation_1000" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="210"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_Final_01" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(gini-index-reserve / count turtles) / 0.5</metric>
    <metric>count turtles with [color = red] / count turtles * 100</metric>
    <metric>count turtles with [color = green] / count turtles * 100</metric>
    <metric>count turtles with [color = blue] / count turtles * 100</metric>
    <metric>count turtles</metric>
    <metric>median [wealth] of turtles with [color = red]</metric>
    <metric>median [wealth] of turtles with [color = green]</metric>
    <metric>median [wealth] of turtles with [color = blue]</metric>
    <enumeratedValueSet variable="chance-to-marry">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-utility-grown">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-growth-chance-per-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-adult-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigration-rate">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inheritance-Tax">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance-tax-allowance">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225
@#$#@#$#@
0
@#$#@#$#@
