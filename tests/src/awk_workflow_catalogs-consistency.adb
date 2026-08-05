with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Messages.Consistency;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Catalogs.Consistency is
   package U renames Ada.Strings.Unbounded;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
      Tokens : constant Messages.Consistency.Token_Array :=
        [U.To_Unbounded_String ("awk"),
         U.To_Unbounded_String ("awklib"),
         U.To_Unbounded_String ("-F"),
         U.To_Unbounded_String ("-v"),
         U.To_Unbounded_String ("-f"),
         U.To_Unbounded_String ("--help"),
         U.To_Unbounded_String ("--version"),
         U.To_Unbounded_String ("--color"),
         U.To_Unbounded_String ("--"),
         U.To_Unbounded_String ("ARGV"),
         U.To_Unbounded_String ("ARGC"),
         U.To_Unbounded_String ("ENVIRON"),
         U.To_Unbounded_String ("BEGIN"),
         U.To_Unbounded_String ("END"),
         U.To_Unbounded_String ("getline"),
         U.To_Unbounded_String ("print"),
         U.To_Unbounded_String ("printf"),
         U.To_Unbounded_String ("POSIX"),
         U.To_Unbounded_String ("MIT")];
      Findings : Messages.Consistency.Report;
   begin
      Messages.Consistency.Check_File
        (Path     => "../resources/messages/catalog.txt",
         Verbatim => Tokens,
         Into     => Findings);

      for Index in 1 .. Findings.Count loop
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            ("translation consistency finding: "
             & Messages.Consistency.Image (Findings.Items (Index))));
      end loop;

      Require
        (Findings.Count = 0,
         "translation consistency check reported findings");

      Require
        (not Findings.Overflow,
         "translation consistency produced more findings than the report holds");
   end Run;
end Awk_Workflow_Catalogs.Consistency;
