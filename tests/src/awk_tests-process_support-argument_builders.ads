package Awk_Tests.Process_Support.Argument_Builders is
   function Argument (Value : String) return U.Unbounded_String;
   function No_Arguments return Process_Arguments;
   function Arguments (Items : Argument_Items) return Process_Arguments;
end Awk_Tests.Process_Support.Argument_Builders;
