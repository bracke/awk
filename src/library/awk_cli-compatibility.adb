package body Awk_CLI.Compatibility is
   function Count return Natural is (0);

   function Id (Index : Positive) return String is
      pragma Unreferenced (Index);
   begin
      return (raise Constraint_Error with "no compatibility entry");
   end Id;

   function Area (Index : Positive) return Compatibility_Area is
      pragma Unreferenced (Index);
   begin
      return (raise Constraint_Error with "no compatibility entry");
   end Area;

   function Status (Index : Positive) return Compatibility_Status is
      pragma Unreferenced (Index);
   begin
      return (raise Constraint_Error with "no compatibility entry");
   end Status;

   function Description (Index : Positive) return String is
      pragma Unreferenced (Index);
   begin
      return (raise Constraint_Error with "no compatibility entry");
   end Description;

   function Source (Index : Positive) return String is
      pragma Unreferenced (Index);
   begin
      return (raise Constraint_Error with "no compatibility entry");
   end Source;

   function Documentation (Index : Positive) return String is
      pragma Unreferenced (Index);
   begin
      return (raise Constraint_Error with "no compatibility entry");
   end Documentation;

   function Test_Reference (Index : Positive) return String is
      pragma Unreferenced (Index);
   begin
      return (raise Constraint_Error with "no compatibility entry");
   end Test_Reference;

   function Has_Id (Value : String) return Boolean is
      pragma Unreferenced (Value);
   begin
      return False;
   end Has_Id;
end Awk_CLI.Compatibility;
