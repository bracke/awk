with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI;
with Awk_CLI.Environment;
with Awk_Tests.Support;

package body Awk_Tests.Environment is
   use AUnit.Assertions;
   use Awk_Tests.Support;
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];
   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk environment");
   end Name;

   procedure Test_Context_Environment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ENVIRON[""AWK_TEST_ENV""] }");
      Awk_CLI.Add_Environment (Context, "AWK_TEST_ENV", "present");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "environment run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "present" & LF,
              "environment entry reaches awklib");
   end Test_Context_Environment;

   procedure Test_Environment_Normalization (T : in out AUnit.Test_Cases.Test_Case'Class) is
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
         Assert (U.To_String (Normal.Element (1).Name) = "AWK_DUP",
                 "duplicate entry keeps original position");
         Assert (U.To_String (Normal.Element (1).Value) = "second",
                 "duplicate entry uses final value");
         Assert (U.To_String (Normal.Element (2).Name) = "AWK_OTHER",
                 "other entry order is preserved");
      end;
   end Test_Environment_Normalization;

   procedure Test_Environment_Normalization_Edges
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
         Assert (Normal.Length = 3, "empty values are retained and names remain case-sensitive");
         Assert (U.To_String (Normal.Element (1).Name) = "EMPTY_VALUE",
                 "duplicate with empty first value keeps original position");
         Assert (U.To_String (Normal.Element (1).Value) = "final",
                 "duplicate with empty first value uses final value");
         Assert (U.To_String (Normal.Element (2).Name) = "Case_Name",
                 "mixed-case environment name is preserved");
         Assert (U.To_String (Normal.Element (2).Value) = "mixed",
                 "mixed-case environment value is preserved");
         Assert (U.To_String (Normal.Element (3).Name) = "CASE_NAME",
                 "case-distinct environment name is not collapsed");
         Assert (U.To_String (Normal.Element (3).Value) = "upper",
                 "case-distinct environment value is preserved");
      end;
   end Test_Environment_Normalization_Edges;

   procedure Test_Context_Environment_Normalization_And_Confidentiality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ENVIRON[""AWK_DUP""]; print ENVIRON[""""] }");
      Awk_CLI.Add_Environment (Context, "AWK_DUP", "old-secret");
      Awk_CLI.Add_Environment (Context, "", "empty-secret");
      Awk_CLI.Add_Environment (Context, "AWK_DUP", "new-secret");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "normalized environment run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "new-secret" & LF & LF,
              "duplicate env uses final value and empty env name is ignored");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Add_Argument (Context, "missing.txt");
      Awk_CLI.Add_Environment (Context, "AWK_SECRET", "do-not-leak");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "missing input remains host I/O");
      Assert (not Contains (Awk_CLI.Standard_Error (Context), "do-not-leak"),
              "environment values are not emitted in unrelated diagnostics");
   end Test_Context_Environment_Normalization_And_Confidentiality;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Context_Environment'Access,
         "context environment");
      Registration.Register_Routine
        (T, Test_Environment_Normalization'Access,
         "environment normalization");
      Registration.Register_Routine
        (T, Test_Environment_Normalization_Edges'Access,
         "environment normalization edges");
      Registration.Register_Routine
        (T, Test_Context_Environment_Normalization_And_Confidentiality'Access,
         "context environment normalization confidentiality");
   end Register_Tests;
end Awk_Tests.Environment;
