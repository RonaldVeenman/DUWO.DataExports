table 60301 "DUWO Data Export Field Setup"
{
    Caption = 'Data Export Field Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = "DUWO Data Export Table Setup"."Table No.";
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';

            trigger OnValidate()
            var
                TableSetup: Record "DUWO Data Export Table Setup";
                FieldRec: Record Field;
            begin
                if TableSetup.Get("Table No.") then
                    if FieldRec.Get(TableSetup."Table No.", "Field No.") then begin
                        "Field Name" := CopyStr(FieldRec.FieldName, 1, MaxStrLen("Field Name"));
                        "Field Caption" := CopyStr(FieldRec."Field Caption", 1, MaxStrLen("Field Caption"));
                        "Field Type" := CopyStr(Format(FieldRec.Type), 1, MaxStrLen("Field Type"));
                        "Is FlowField" := FieldRec.Class = FieldRec.Class::FlowField;
                    end;
            end;

            trigger OnLookup()
            var
                TableSetup: Record "DUWO Data Export Table Setup";
                FieldRec: Record Field;
                FieldListPage: Page "Fields Lookup";
            begin
                if not TableSetup.Get("Table No.") then
                    exit;

                FieldRec.SetRange(TableNo, TableSetup."Table No.");
                FieldListPage.SetTableView(FieldRec);
                FieldListPage.LookupMode(true);
                if FieldListPage.RunModal() = Action::LookupOK then begin
                    FieldListPage.GetRecord(FieldRec);
                    Validate("Field No.", FieldRec."No.");
                end;
            end;
        }
        field(3; "Field Name"; Text[250])
        {
            Caption = 'Field Name';
            Editable = false;
        }
        field(4; "Field Caption"; Text[250])
        {
            Caption = 'Field Caption';
            Editable = false;
        }
        field(5; "Field Type"; Text[30])
        {
            Caption = 'Field Type';
            Editable = false;
        }
        field(6; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(7; "Is FlowField"; Boolean)
        {
            Caption = 'Is FlowField';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Table No.", "Field No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Enabled")
        {
        }
    }
}
