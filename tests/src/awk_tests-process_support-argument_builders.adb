with Project_Tools.Processes;

package body Awk_Tests.Process_Support.Argument_Builders is
   function Argument (Value : String) return U.Unbounded_String is
     (Project_Tools.Processes.Argument (Value));

   function No_Arguments return Process_Arguments is
     (Project_Tools.Processes.No_Arguments);

   function Arguments (Items : Argument_Items) return Process_Arguments is
     (Project_Tools.Processes.Arguments (Project_Tools.Processes.Argument_Items (Items)));
end Awk_Tests.Process_Support.Argument_Builders;
