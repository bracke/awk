package Awk_CLI is
   type Exit_Code is range 0 .. 255;

   type Invocation_Context is tagged limited private;

   procedure Initialize_From_Process (Context : in out Invocation_Context);
   function Run (Context : in out Invocation_Context) return Exit_Code;

private
   type Invocation_Context is tagged limited null record;
end Awk_CLI;
