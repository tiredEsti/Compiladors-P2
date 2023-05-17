# Calculator
This is a simple command-line 3-Address-Code generator program that can evaluate mathematical expressions and "REPEAT expression DO intructions DONE" flow control statements. It supports basic mathematical operations (addition, subtraction, multiplication, division, mod and pow).

## Implementation Details
The program uses a combination of Flex and Bison to tokenize and parse the input expressions. The tokenized expressions are then evaluated using a simple algorithm. Variables are saved in has table according to the provided symtab functionality.

* syn.y: Bison grammar file that defines the grammar rules for the calculator. It includes the other necessary functions, as well as the main function
* lex.l: Flex file that defines the regular expressions for the lexer
* symtab.c: Symbol table implementation for storing variables and their values
* calc.tab.c and calc.tab.h: Generated files from Bison
* lex.yy.c: Generated file from Flex

## Compiling and Running the Program
To compile the program, you need to have Flex and Bison installed. You can then use the provided Makefile to build the program:

Copy code
```
make
```
This will create the calc executable.

To run the program, simply execute the calc executable and enter an expression:

Copy code
```
./syn input.txt
```
To clean the object files and executables copy code
```
make clean
```

##DESIGN DECISIONS AND NOTES

//Structs
* For the variable type, this time we will save the values all as strings.
* Name will contain the name of id's. Type functions as the previous time, with UNDEFINED type to control errors.
* Place will contain what needs to be printed for each expression, either the name for id's, or the temporal variables were the results are stored.
* Ctr is where the variable for loop control is saved (initilized as 0, 1 added in each loop)
* Repeat is an int, corresponding to the line where loop has to jump back.
* I have chosen to save the 3AC code in a list of quad variables, following the Compilers book, but I would think in this case, an array of strings would have sufficed.
* In quad we have 4 numbered variables. Theoretically they correlate to 3AC in this order: result, v1, operator, v2. In this practical application, however, I also use quads to save other types of calls, like PARAM, CALL, etc.

//Lexer
* Not much to comment from the previous edition. I simply added the loop statements, and made it so the numbers were saved as strings.


//Syntax analizer
* Much from this project has been adapted from the Calculator project. 
* I added the addQuad function, which has a variable number of string arguments as input, and saves them as a quad in the quad_list, updating the corresponding variables.
* NewTemp() simply generates a new string corresponding to the most recent temporal variable
* ArithmeticCalc, as in the previous project, is responsible for type checking, changing and corresponding quad generation for arithmetic operations.
* PowFunction is done separatedly and I chose to implement it as a repetition of the multiplication, since as instructed, there is no function call for pow operations. 
* Finally the printQuad function is called to correctly print the quad_list at the end of the program. According to the statements prints the correct arguments, separating CALL, PARAM, CHS, arithmetic operations, etc.
*For this implementation, it would be best not to name any variables starting with LT, since it coudl confuse the print function. It could be fixed changing the quad structure, but I chose to try to implement it with the "pure" quad function.

//Errors
* Errors are controlled as they were for the Calculator project, but this time I chose not to print them on the screen, to not mix them with 3AC. Instead, they are printed in the log file, and properly dealt with (instructions ignored). 
* For the loops, errors are also controlled, and the loop operation aborted, but the instructions inside are executed once. I couldn't stop the statement_list execution in the loop. Of course, the errors are logged in the file.
* In case the loop condition is negative, the loop proceeds as normal, and it would enter an infinite loop, as it is what happens in some cases.
* In all cases, the execution continues, as suggested by the project instructions, but personally I feel aborting the execution (as do the normal compilers) would be a better decision for a functional project.
*File errors are checked in the main function

//INPUTS
* Number 1 is the provided example
* Number 2 contains error control and test of multiline comments and pow
* Number 3 contains loop tests