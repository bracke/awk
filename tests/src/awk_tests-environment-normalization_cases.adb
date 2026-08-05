with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Environment;

package body Awk_Tests.Environment.Normalization_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;

   use type Ada.Containers.Count_Type;

   procedure Test_Normalization (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Raw : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.Null_Unbounded_String,
            Value => U.To_Unbounded_String ("ignored")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("AWK_DUP"),
            Value => U.To_Unbounded_String ("first")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("AWK_OTHER"),
            Value => U.To_Unbounded_String ("kept")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("AWK_DUP"),
            Value => U.To_Unbounded_String ("second")));

      declare
         Normal : constant Awk_CLI.Environment.Entry_Vectors.Vector :=
           Awk_CLI.Environment.Normalize (Raw);
      begin
         Assert (Normal.Length = 2, "empty names are filtered and duplicates collapse");
         Assert
           (U.To_String (Normal.Element (1).Name) = "AWK_DUP",
            "duplicate entry keeps original position");
         Assert
           (U.To_String (Normal.Element (1).Value) = "second",
            "duplicate entry uses final value");
         Assert
           (U.To_String (Normal.Element (2).Name) = "AWK_OTHER",
            "other entry order is preserved");
      end;
   end Test_Normalization;

   procedure Test_Normalization_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("EMPTY_VALUE"),
            Value => U.Null_Unbounded_String));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("Case_Name"),
            Value => U.To_Unbounded_String ("mixed")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("CASE_NAME"),
            Value => U.To_Unbounded_String ("upper")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("EMPTY_VALUE"),
            Value => U.To_Unbounded_String ("final")));

      declare
         Normal : constant Awk_CLI.Environment.Entry_Vectors.Vector :=
           Awk_CLI.Environment.Normalize (Raw);
      begin
         Assert
           (Normal.Length = 3,
            "empty values are retained and names remain case-sensitive");
         Assert
           (U.To_String (Normal.Element (1).Name) = "EMPTY_VALUE",
            "duplicate with empty first value keeps original position");
         Assert
           (U.To_String (Normal.Element (1).Value) = "final",
            "duplicate with empty first value uses final value");
         Assert
           (U.To_String (Normal.Element (2).Name) = "Case_Name",
            "mixed-case environment name is preserved");
         Assert
           (U.To_String (Normal.Element (2).Value) = "mixed",
            "mixed-case environment value is preserved");
         Assert
           (U.To_String (Normal.Element (3).Name) = "CASE_NAME",
            "case-distinct environment name is not collapsed");
         Assert
           (U.To_String (Normal.Element (3).Value) = "upper",
            "case-distinct environment value is preserved");
      end;
   end Test_Normalization_Edges;
end Awk_Tests.Environment.Normalization_Cases;
