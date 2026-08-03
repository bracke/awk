package body Awk_Conformance_Cases is
   function Id (Index : Positive) return String is
   begin
      case Index is
         when 1 =>
            return "AWK-CONF-PRINT-001";
         when 2 =>
            return "AWK-CONF-FIELDS-001";
         when 3 =>
            return "AWK-CONF-ASSIGNMENT-001";
         when 4 =>
            return "AWK-CONF-REDIRECTION-001";
         when 5 =>
            return "AWK-CONF-GETLINE-001";
         when others =>
            raise Constraint_Error;
      end case;
   end Id;

   function Status (Index : Positive) return String is
      pragma Unreferenced (Index);
   begin
      return "Supported";
   end Status;

   function Case_File (Index : Positive) return String is
   begin
      case Index is
         when 1 =>
            return "cases/print_record.awk";
         when 2 =>
            return "cases/print_first_field.awk";
         when 3 =>
            return "cases/runtime_assignment.awk";
         when 4 =>
            return "cases/append_redirection.awk";
         when 5 =>
            return "cases/command_getline.awk";
         when others =>
            raise Constraint_Error;
      end case;
   end Case_File;

   function Expected_File (Index : Positive) return String is
   begin
      case Index is
         when 1 =>
            return "expected/print_record.txt";
         when 2 =>
            return "expected/print_first_field.txt";
         when 3 =>
            return "expected/runtime_assignment.txt";
         when 4 =>
            return "expected/append_redirection.txt";
         when 5 =>
            return "expected/command_getline.txt";
         when others =>
            raise Constraint_Error;
      end case;
   end Expected_File;

   function Reference (Index : Positive) return String is
   begin
      case Index is
         when 1 =>
            return "basic print through awklib";
         when 2 =>
            return "field processing through awklib";
         when 3 =>
            return "positional runtime assignment supported";
         when 4 =>
            return "append redirection supported through awklib streaming callbacks";
         when 5 =>
            return "command getline supported through awklib callback";
         when others =>
            raise Constraint_Error;
      end case;
   end Reference;

   function Manifest_Line (Index : Positive) return String is
     (Id (Index) & "|" & Status (Index) & "|" & Case_File (Index) & "|"
      & Expected_File (Index) & "|" & Reference (Index));
end Awk_Conformance_Cases;
