module tb;
  int arr[];
  int cpr[];
  int mrg[];
  
  initial begin
    arr=new[5];
    arr={1,2,3,4,5};
    $display("array1:%p",arr);
    cpr=arr; 
    $display("array2:%p",cpr);
    arr[2]=8;
    $display("array1:%p  array2=%p",arr,cpr); //arr and cpr have different memory location
    mrg=new[arr.size()+2](arr); //size 2 more than the arr
    $display("array merged:%p",mrg); //additional location initialized with zero
    mrg.delete();
    $display("deleted array:%p",mrg);
  end
endmodule
