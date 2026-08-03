package Awk_Workflow_Drift is
   --  Drift checks that compare compiled behavior constants with docs/catalogs.

   procedure Exit_Statuses;
   --  Validate documented exit statuses against compiled constants.

   procedure Options;
   --  Validate command-line option spellings across reference docs and help text.
end Awk_Workflow_Drift;
