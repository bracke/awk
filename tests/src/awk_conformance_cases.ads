package Awk_Conformance_Cases is
   Case_Count : constant Positive := 5;

   function Id (Index : Positive) return String
     with Pre => Index <= Case_Count;
   --  @param Index Case index in the registry.
   --  @return Stable conformance case identifier.

   function Status (Index : Positive) return String
     with Pre => Index <= Case_Count;
   --  @param Index Case index in the registry.
   --  @return Compatibility status for the case.

   function Case_File (Index : Positive) return String
     with Pre => Index <= Case_Count;
   --  @param Index Case index in the registry.
   --  @return Program file path relative to tests/conformance.

   function Expected_File (Index : Positive) return String
     with Pre => Index <= Case_Count;
   --  @param Index Case index in the registry.
   --  @return Expected-output path relative to tests/conformance.

   function Reference (Index : Positive) return String
     with Pre => Index <= Case_Count;
   --  @param Index Case index in the registry.
   --  @return Brief case purpose or upstream-behavior reference.

   function Manifest_Line (Index : Positive) return String
     with Pre => Index <= Case_Count;
   --  @param Index Case index in the registry.
   --  @return Exact manifest line expected for the case.
end Awk_Conformance_Cases;
