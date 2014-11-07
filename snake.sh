#!/bin/bash


initgame ()
{
    # Reset terminal to current state upon exit.
    trap "stty $(stty -g)" EXIT

    # Disable echo and special characters, set input timeout to 0.2 seconds.
    stty -echo -icanon || exit $?

    tput init
    tput setb 7
    tput clear
    tput civis

    #Detect terminal resolution
    width=$(tput lines)
    height=$(tput cols)

    #Initalize game variables
    #Direction 1 - right; 2 - bottom; 3 - left; 4 - top;
    movement=1
    score=0
    snake0y=`expr $width / 2`
    snake0x=`expr $height / 2`
    snake_lenght=5
    drawn_steps=0
}

move_snake ()
{
    snake_tail_id=`expr $snake_lenght`

    # Moving each body part
    for (( id = $snake_tail_id; id >= 1; id-- )); do
        eval snake"$id"x='$snake'`expr $id - 1`x
        eval snake"$id"y='$snake'`expr $id - 1`y
    done

    # Removing tail
    # echo tput cup `echo '\$snake\`echo $snake_tail_id\`x \$snake\`echo $snake_tail_id\`y'`
    eval snake_tail_x='$snake'`echo $snake_tail_id`x
    eval snake_tail_y='$snake'`echo $snake_tail_id`y
    snake_tail_position="$snake_tail_y $snake_tail_x"
    tput cup "$snake_tail_y" "$snake_tail_x"
    echo -n " "

    # Handling movement
    if [[ $movement -eq 1 ]]; then
        snake0x=`expr $snake0x + 1`
    fi

    if [[ $movement -eq 2 ]]; then
        snake0y=`expr $snake0y + 1`
    fi

    if [[ $movement -eq 3 ]]; then
        snake0x=`expr $snake0x - 1`
    fi

    if [[ $movement -eq 4 ]]; then
        snake0y=`expr $snake0y - 1`
    fi

    check_out_of_scope

    # Drawing head
    tput cup $snake0y $snake0x
    tput setb 0
    tput setf 0
    echo -n "*"
    tput setb 7
}

die ()
{
    tput clear
    # $1 is message
    echo "$1"
    echo "Score: $score"
    echo "Press any key."
    sleep 1.5
    read -n1
    tput sgr0
    tput clear
    read -t 0.001 -n 1000000 discard

    if [[ $score -ge 5 ]]; then
        name=$(getent passwd `whoami` | cut -d ":"  -f5 | cut -d "," -f1)
        scoreline="$score - $name"
        echo $scoreline >> scores.snake
        sort -n scores.snake -r -o scores.snake
        less scores.snake
    fi

    exit
}

check_out_of_scope ()
{
    local msg="Game Over."
    if [[ $snake0x -lt "0" ]]; then
        die "$msg"
    fi

    if [[ $snake0y -lt "0" ]]; then
        die "$msg"
    fi

    if [[ $snake0y -gt $width ]]; then
        die "$msg"
    fi

    if [[ $snake0x -gt $height ]]; then
        die "$msg"
    fi

}

check_collision ()
{
    if [[ `is_snake_tail $snake0x $snake0y` != "false" ]]; then
        die "You ate your own tail. Game over."
    fi
}

handle_control ()
{
    read -n1 -t0.15 key
    case $key in
      $'h' | $'a' ) if [[ movement -ne 1 ]]; then
        movement=3
      fi ;;
      $'j' | $'s') if [[ movement -ne 4 ]]; then
        movement=2
      fi;;
      $'k' | $'w' ) if [[ movement -ne 2 ]]; then
        movement=4
      fi ;;
      $'l' | $'d' ) if [[ movement -ne 3 ]]; then
        movement=1
      fi ;;
      ?) movement=$movement ;;
      *) movement=$movement ;;
    esac
}

check_food ()
{
    if [[ $food_x -eq $snake0x ]]; then
        if [[ $food_y -eq $snake0y ]]; then
            snake_lenght=`expr $snake_lenght + 1`
            score=`expr $score + 1`
            place_food
        fi
    fi
}

place_food ()
{
    food_y=$((RANDOM%`echo $width`))
    food_x=$((RANDOM%`echo $height`))

    collision=`is_snake_tail_or_snake_head $food_x $food_y`

    if [[ $collision == "true" ]]; then
        place_food
    else
        draw_food
    fi
}

is_snake_tail ()
{
    snake_tail_id=`expr $snake_lenght`
    collision="false"
    for (( id = $snake_tail_id; id > 0; id-- )); do
        eval testx='$snake'"$id"x
        eval testy='$snake'"$id"y

        if [[ $testx -eq $1 ]]; then
            if [[ $testy -eq $2 ]]; then
                collision="true"
            fi
        fi
    done

    if [[ $drawn_steps -le $snake_lenght ]]; then
        collision="false"
    fi

    echo $collision
    return 1
}

is_snake_tail_or_snake_head ()
{
    if [[ `is_snake_tail $1 $2` != "false" ]]; then
        echo `is_snake_tail $1 $2`
        return 1
    fi

    if [[ $1 -eq $snake0x ]]; then
        if [[ $2 -eq $snake0y ]]; then
            echo "true"
            return 1
        fi
    fi
    echo "false"
    return 1
}

draw_food ()
{
    tput cup $food_y $food_x
    tput setf 1
    echo -n "o"
}

main()
{
    initgame

    place_food

    while [[ true ]]; do
        check_food
        move_snake
        handle_control
        check_collision
        drawn_steps=`expr $drawn_steps + 1`
    done
}

main
