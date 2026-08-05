with Awk_Tests.Environment.Context_Cases;
with Awk_Tests.Environment.Normalization_Cases;

package body Awk_Tests.Environment is
   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk environment");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Awk_Tests.Environment.Context_Cases.Test_Context_Environment'Access,
         "context environment");
      Registration.Register_Routine
        (T, Awk_Tests.Environment.Normalization_Cases.Test_Normalization'Access,
         "environment normalization");
      Registration.Register_Routine
        (T, Awk_Tests.Environment.Normalization_Cases.Test_Normalization_Edges'Access,
         "environment normalization edges");
      Registration.Register_Routine
        (T, Awk_Tests.Environment.Context_Cases.Test_Normalization_And_Confidentiality'Access,
         "context environment normalization confidentiality");
   end Register_Tests;
end Awk_Tests.Environment;
