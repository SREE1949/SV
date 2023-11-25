//****************transaction**********************

class transaction;
  bit we;
  bit re;
  bit full;
  bit empty;
  bit [7:0] rdata;
  bit [7:0] wdata;
  rand bit opr;
  
  constraint opr_con {opr dist{1:/50,0:/50};}
  
  function void print();
    $display("opr=%0d || we=%0d re=%0d full=%0d empty=%0d rdata=%0d wdata=%0d",opr,we,re,full,empty,rdata,wdata);
  endfunction  
endclass


//****************generator***********************
class generator;
  transaction tr;
  mailbox #(transaction) mbx;  // to send data to driver
  event next;
  event done;
  
  function new(mailbox #(transaction) mbx);
    tr=new();
    this.mbx=mbx;
  endfunction
  
  task run();
    repeat(10) begin
      assert(tr.randomize) else $error("randomization failed");
      mbx.put(tr);
      $display("[GEN] : operation:%0d",tr.opr);
      @(next);
    end
    ->done;
  endtask
  
endclass


//*************************driver*************************

class driver;
  transaction tr;
  mailbox #(transaction) mbx;
  virtual fifo_if vif;
  
  function new(mailbox #(transaction) mbx);
    this.mbx=mbx;
  endfunction
  
  task reset();
    vif.re <= 1'b0;
    vif.we <= 1'b0;
    vif.rst <= 1'b1;
    vif.wdata <= 0;
    repeat(4) @(posedge vif.clk);
    vif.rst <= 1'b0;
    $display("[DRV]: Reset done");
  endtask
  
  task read();
    @(posedge vif.clk);
    vif.re <= 1'b1;
    vif.we <= 1'b0;
    vif.rst <= 1'b0;
    @(posedge vif.clk)
    vif.re <= 1'b0;
    $display("[DRV]: Data read");
    @(posedge vif.clk);
  endtask
  
  task write();
    @(posedge vif.clk);
    vif.re <= 1'b0;
    vif.we <= 1'b1;
    vif.rst <= 1'b0;
    vif.wdata <= $urandom_range(1,20);
    @(posedge vif.clk)
    vif.we <= 1'b0;
    $display("[DRV]: Data write :%0d",vif.wdata);
    @(posedge vif.clk);    
  endtask
  
  task run();
    forever begin
      mbx.get(tr);
      //tr.print(); //to troubleshoot
      if(tr.opr)
        write();
      else
        read();
    end
  endtask
endclass


//*******************monitor**************************

class monitor;
  transaction tr;
  mailbox #(transaction) mbx;
  virtual fifo_if vif;
  
  function new(mailbox #(transaction) mbx);
    this.mbx=mbx;
    tr=new();
  endfunction
  
  task run();
    forever begin  
      repeat(2) @(posedge vif.clk);
      tr.we=vif.we;
      tr.re=vif.re;
      tr.full=vif.full;
      tr.empty=vif.empty;
      tr.wdata=vif.wdata;
      @(posedge vif.clk)
      tr.rdata=vif.rdata;
      //$display("monitor");
      //tr.print();
      mbx.put(tr);
    end
  endtask
  
endclass


//*****************scoreboard**************************8
class scoreboard;
  transaction tr;
  mailbox #(transaction) mbx;
  bit [7:0] mem[$];
  bit [7:0] data;
  event next;
  
  function new(mailbox #(transaction) mbx);
    this.mbx=mbx;
  endfunction
  
  task run();
    forever begin
      mbx.get(tr);
      //tr.print();
      
      if(tr.we==1'b1) begin
        if(tr.full==1'b0) begin
          mem.push_front(tr.wdata);
          $display("data entered");
        end
        else
          $display("[SCR]: FIFO Full");
      end
      
      if(tr.re==1'b1) begin
        if(tr.empty==1'b0)begin
          data=mem.pop_back();
          $display("Data in Q :%0d",data);
          if(data==tr.rdata)
            $display("[SCR]: data match");
          else
            $display("[SCR]: data mismatch");
        end
        else
          $display("[SCR]: FIFO Empty");
      end
      $display("||||||||||||||||||||||||||||||||||||||||||||||||");
      ->next;
    end
  endtask
endclass
          
//********************environment********************          
class env;

  generator gen;
  driver drv;
  monitor mon;
  scoreboard scr;
  event next;
  mailbox #(transaction) gd_mbx;
  mailbox #(transaction) ms_mbx;

  virtual fifo_if vif;
  
  function new(virtual fifo_if vif);
    gd_mbx=new();
    ms_mbx=new();
    this.vif=vif;
    
    gen=new(gd_mbx);
    drv=new(gd_mbx);
    mon=new(ms_mbx);
    scr=new(ms_mbx);
    mon.vif=this.vif;
    drv.vif=this.vif;
    gen.next=this.next;
    scr.next=this.next;
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      scr.run();
    join_any
  endtask
  
  task post_test();
    wait(gen.done.triggered);
    $display("------------Test finished------------");
    $finish;
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass


// ***********************testbench**********************************
module tb;
  fifo_if vif();
  fifo dut(vif);
  initial begin
    vif.clk <= 0;
  end
  
  always #5 vif.clk <= ~vif.clk;
  
  env ev;
  
  initial begin
    ev=new(vif);
    ev.run();
  end
  
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars;
  end
  
endmodule
  
            
        
