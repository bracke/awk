with Awk_Tests.CLI_Options;
with Awk_Tests.Compatibility;
with Awk_Tests.Context;
with Awk_Tests.Diagnostics;
with Awk_Tests.Environment;
with Awk_Tests.Execution;
with Awk_Tests.Inputs;
with Awk_Tests.Localization;
with Awk_Tests.Operands;
with Awk_Tests.Process;
with Awk_Tests.Program_Sources;
with Awk_Tests.Redirections;
with Awk_Tests.Terminal_Styles;

package body Awk_Tests.Suite is
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
   begin
      pragma Warnings (Off, "use of an anonymous access type allocator");
      Result.Add_Test (new Awk_Tests.CLI_Options.Case_Type);
      Result.Add_Test (new Awk_Tests.Compatibility.Case_Type);
      Result.Add_Test (new Awk_Tests.Context.Case_Type);
      Result.Add_Test (new Awk_Tests.Diagnostics.Case_Type);
      Result.Add_Test (new Awk_Tests.Environment.Case_Type);
      Result.Add_Test (new Awk_Tests.Execution.Case_Type);
      Result.Add_Test (new Awk_Tests.Inputs.Case_Type);
      Result.Add_Test (new Awk_Tests.Localization.Case_Type);
      Result.Add_Test (new Awk_Tests.Operands.Case_Type);
      Result.Add_Test (new Awk_Tests.Process.Case_Type);
      Result.Add_Test (new Awk_Tests.Program_Sources.Case_Type);
      Result.Add_Test (new Awk_Tests.Redirections.Case_Type);
      Result.Add_Test (new Awk_Tests.Terminal_Styles.Case_Type);
      pragma Warnings (On, "use of an anonymous access type allocator");
      return Result;
   end Suite;
end Awk_Tests.Suite;
