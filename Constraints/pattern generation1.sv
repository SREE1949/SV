//gereate 8 bit address which is random and skip next two consecutive address'
//the pattern genreated in a dynamic array. Number of address reqired can be give as size of array.

class abc;
  rand bit[7:0] addr[];
  
  constraint adr_c {foreach(addr[i])    
    addr[i]==addr[i+1]-3;
                   }
  
  function new(int c);
    addr=new[c];
  endfunction
  
  function void display();
    $display("The value : %p",addr);
  endfunction
endclass

module tb;
  abc obj;
  initial begin
    obj=new(5);
    //repeat(5) begin
      obj.randomize();
      obj.display();
   // end
  end
 
endmodule
