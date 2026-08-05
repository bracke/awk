with Project_Tools.Release_Checks;
with Project_Tools.Source_Budgets;

package body Awk_Workflow_Source_Policy.Source_Budget_Checks is
   package Source_Budgets renames Project_Tools.Source_Budgets;

   procedure Run is
      Errors : Natural := 0;
   begin
      Source_Budgets.Check_Structural_Baseline
        (Errors          => Errors,
         Root            => "..",
         Manifest_Path   => "tests/source-budgets.toml",
         Minimum_Entries => 16,
         Purpose         => "awk source budget",
         Section         => "body",
         Quiet           => False);
      Source_Budgets.Check_Large_Source_Budget_Coverage
        (Errors        => Errors,
         Root          => "..",
         Source_Dir    => "src/library",
         Minimum_Lines => 300,
         Manifests     =>
           [Source_Budgets.Coverage_Manifest_Entry
              ("tests/source-budgets.toml", "body")],
         Purpose       => "production large-source budget coverage",
         Quiet         => False);
      Source_Budgets.Check_Large_Source_Budget_Coverage
        (Errors        => Errors,
         Root          => "..",
         Source_Dir    => "tests/src",
         Minimum_Lines => 300,
         Manifests     =>
           [Source_Budgets.Coverage_Manifest_Entry
              ("tests/source-budgets.toml", "body")],
         Purpose       => "test large-source budget coverage",
         Quiet         => False);

      if Errors /= 0 then
         Project_Tools.Release_Checks.Fail ("source budget checks failed");
      end if;
   end Run;
end Awk_Workflow_Source_Policy.Source_Budget_Checks;
