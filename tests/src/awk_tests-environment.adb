with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI;
with Awk_CLI.Environment;

package body Awk_Tests.Environment is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];
   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk environment");
   end Name;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;
      if Text'Length < Pattern'Length then
         return False;
      end if;
      for Index in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (Index .. Index + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

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
        (T, Test_Context_Environment_Normalization_And_Confidentiality'Access,
         "context environment normalization confidentiality");
   end Register_Tests;
end Awk_Tests.Environment;
