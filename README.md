# CPU Project

## Summary
This repository include single-cycle CPU and pipelined CPU. these CPUs support arithmetic and logic operation. In addition, these CPUs can read and write to external FIFO memory.

## List of Aailable Oeration
* NOP         
* INC         
* ADD         
* ADD_INC     
* SUB_1C      
* SUB         
* DEC         
* MOV         
* AND         
* OR          
* XOR         
* NOT         
* SHIFT_RIGHT 
* SHIFT_LEFT  
* LOAD_FIFO
* STORE_FIFO
* STORE       
* LOAD        
* ADD_IM      
* SUB_1C_IM   
* SUB_IM      
* MOV_IM      
* AND_IM      
* OR_IM       
* XOR_IM      
* BRANCH_C    
* BRANCH_NC   
* BRANCH_Z    
* BRANCH_NZ   
* BRANCH_O    
* BRANCH_NO   
* BRANCH_N    
* BRANCH_P    
* JUMP        
* HALT        
 
 ## Interface To External FIFO Memory
 Every request to the FIFO for read or write build from two words.
 * Word 1:
   * D15:D1 - number of words to write (available only on write requset).
   * D0 - request type. 0 = read | 1 = write.
 * Word 2: 
   * D15:D0 - RAM address to read or write.

## Test Bach
* The file *data_ram.mem* is for simulat RAM memory.
* The file *inst_rom.mem* is for simulat ROM memory. this file has program to cpu execute in HEX code. using *Assembler.xlsx* file we can convert from Assembler anguage to HEX language

