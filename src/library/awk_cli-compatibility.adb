package body Awk_CLI.Compatibility is
   function Count return Natural is (7);

   function Id (Index : Positive) return String is
   begin
      case Index is
         when 1 => return "AWK-COMPAT-REGEX-001";
         when 2 => return "AWK-COMPAT-GETLINE-001";
         when 3 => return "AWK-COMPAT-GETLINE-002";
         when 4 => return "AWK-COMPAT-UTF8-001";
         when 5 => return "AWK-COMPAT-PRINTF-001";
         when 6 => return "AWK-COMPAT-ASSIGNMENT-001";
         when 7 => return "AWK-COMPAT-REDIRECTION-001";
         when others => return (raise Constraint_Error with "no compatibility entry");
      end case;
   end Id;

   function Area (Index : Positive) return Compatibility_Area is
   begin
      case Index is
         when 1 => return Regular_Expressions;
         when 2 | 3 => return Getline;
         when 4 => return Encoding;
         when 5 => return Output_Formatting;
         when 6 => return Command_Line;
         when 7 => return Redirection;
         when others => return (raise Constraint_Error with "no compatibility entry");
      end case;
   end Area;

   function Status (Index : Positive) return Compatibility_Status is
   begin
      case Index is
         when 1 .. 7 => return Supported;
         when others => return (raise Constraint_Error with "no compatibility entry");
      end case;
   end Status;

   function Description (Index : Positive) return String is
   begin
      case Index is
         when 1 =>
            return "regular-expression integration follows resolved awklib behavior";
         when 2 =>
            return "main-input getline from BEGIN is handled by resolved awklib";
         when 3 =>
            return "command getline is handled through the awklib command callback";
         when 4 =>
            return "malformed UTF-8 no longer requires a CLI compatibility limitation";
         when 5 =>
            return "printf %c field-width behavior follows resolved awklib";
         when 6 =>
            return "positional runtime assignments are represented at the CLI boundary";
         when 7 =>
            return "append redirection intent is exposed through awklib streaming callbacks";
         when others =>
            return (raise Constraint_Error with "no compatibility entry");
      end case;
   end Description;

   function Source (Index : Positive) return String is
   begin
      case Index is
         when 1 .. 7 => return "resolved awklib 0.1.0 behavior";
         when others => return (raise Constraint_Error with "no compatibility entry");
      end case;
   end Source;

   function Documentation (Index : Positive) return String is
   begin
      case Index is
         when 1 .. 7 => return "docs/compatibility.md";
         when others => return (raise Constraint_Error with "no compatibility entry");
      end case;
   end Documentation;

   function Test_Reference (Index : Positive) return String is
   begin
      case Index is
         when 1 => return "awk process : process regex arithmetic builtins";
         when 2 => return "awk context : context main getline from BEGIN";
         when 3 => return "awk process : process command getline";
         when 4 => return "awk compatibility : compatibility registry";
         when 5 => return "awk process : process printf formatting";
         when 6 => return "awk process : process runtime assignment positions";
         when 7 => return "awk process : process append redirection";
         when others => return (raise Constraint_Error with "no compatibility entry");
      end case;
   end Test_Reference;

   function Has_Id (Value : String) return Boolean is
   begin
      for Index in 1 .. Count loop
         if Id (Index) = Value then
            return True;
         end if;
      end loop;
      return False;
   end Has_Id;
end Awk_CLI.Compatibility;
