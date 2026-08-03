package Awk_Workflow_Source_Policy is
   --  Source-policy validation gates for the awk workflow executable.

   procedure Run;
   --  Validate package boundaries, source tokens, CI policy, and public docs.

   procedure Package_Manifest_Policy;
   --  Validate release package manifest coverage.
end Awk_Workflow_Source_Policy;
