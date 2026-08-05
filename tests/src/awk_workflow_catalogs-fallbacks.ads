package Awk_Workflow_Catalogs.Fallbacks is
   --  Checks that non-English catalog entries are translated.

   procedure Run (Catalog : String);
   --  Validate that non-English entries do not keep known English fallback text.
end Awk_Workflow_Catalogs.Fallbacks;
