# Red Blue Nim
This is a variant of the standard Nim. There are red and blue marbles. The game starts with a fixed number of marbles given as a command-line parameter. Then the user and computer takes turns picking a marble until only one color is left.  
There are 2 versions of the game. These versions define who wins in the end state. In the standard version, the player whose turn it is when only marbles of one color is left is the loser. While in the misere version, that player is the winner.  
The points are calculated as follows. Each red marble is 2 points and each blue marble is 3 points. For instance, if we are playing the standard version and on my turn 3 blue marbles are left (and no red marbles), then I lose (or you win) 9 points.

## Structure
There is only one file in this submission and that is the game file: "red_blue_nim.lisp"
The beginning of the file defines types, variables, constants and the functions used throughout the program.
Then the last S-expression is what contains the game loop. Overall, a very simple structure

## Eval Function and the Depth Limit
If you look at the source code, you will see that I use an eval function named `eval-fn` for
resource-limited MinMax. In this section, I will explain my reasoning behind the eval function.

My approach to the eval function is the "optimal" approach. Optimal in the sense that it models the min-max value of any state.
This means that given a state, the eval-fn can tell you the min-max value of that state without having to traverse the min-max tree.

### Misere

Let's see the misere version first. In this version whoever makes the game end loses (they cause their opponent to win).
For example, if there are 3 red balls and 1 blue ball left and I take the blue, my opponent wins.

This means that in a game with two optimal opponents, the game will continue until 1 blue marble and 1 red marble remain since no one would want the other to win. 
Then, the player whose turn it is will have to pick the marble with the bigger weight so that their opponent wins the smaller weight (i.e they pick blue)
This means that for the misere, you can either win or lose 2 points, depending on who's turn it was the end. 

How do you know whose turn it is? Well this is simple, look at the sum of red and blue marbles at any given time in the game.
Depending on who started, you can either play on odd sums or on even sums throughout the game, never both. 
Lastly, look at the sum when someone wins (i.e 1 + 0). This is an odd sum. Therefore, the player with the odd sum wins 2 points.

```
(* min-weight (if max-node 1 -1) (if (oddp sum) 1 -1))
```
This is what I check with the above statement in Lisp. If it is max-node's turn and the sum is odd, we return a positive min weight (+2)
Note that if either the sum is even (this means the current player will lose), or max-node is false (it is my opponent's turn), then I multiply the result by -1.

### Standard
With standard, it is a little bit tricky. We do not wait till 1 blue 1 red before we force the game to end, 
We force the game to end anytime there is 1 marble of any color left, that way, me make our opponent lose. 
For the optimal opponents, this will be when 2 red marbles and 1 blue marble are left.
So the terminal state has an even sum (only 2 red marbles left). This means that throughout the game, no one touches a marble that has only 2 left, if not, they make their opponent win.

That is not the end, however, we are missing one thing. What if we are in a state of where only one marble of one color (or both) is left?
Well, it doesn't matter whose turn it is then. We take that marble and make our opponent lose. This is what I check at the beginning of the function.

## Running the Code
To Install SBCL (On Debian flavor of Linux):
```
$ sudo apt install sbcl
```

Just in case, I have provided a copy of sbcl for Linux.

Then run the script as 
```
$ sbcl --script red_blue_nim.lisp
```

## Notes
I only guarantee that this code works on Debian Linux systems and with the SBCL interpreter. This is because SBCL is an implementation of the ANSI Common Lisp standard and I use SBCL-specific variables and/or functions in my code
