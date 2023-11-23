interface fifo_if;
  logic we;
  logic re;
  logic rst;
  logic clk;
  logic[7:0] wdata;
  logic[7:0] rdata;
  logic full;
  logic empty;
endinterface

module fifo(fifo_if fif);
  reg [7:0] mem[15:0]; // fifo memory
  reg [3:0] wptr,rptr; // write and read pointer
  int size=0;
  
  always@(posedge fif.clk) begin
    if(fif.rst) begin
      wptr <= 0;
      rptr <= 0;
      size <= 0;
    end
    
    else begin
      if(fif.we && !fif.full) begin
        mem[wptr] <= fif.wdata;
        wptr +=1;
      end
      else if(fif.re && !fif.empty) begin
        fif.rdata <= mem[rptr];
        rptr +=1;
        size -=1;
      end
    end
  end
  
  assign fif.full = size==15 ? 1'b1 : 1'b0;
  assign fif.empty = size==0 ? 1'b1 : 1'b0;
  
endmodule
    
