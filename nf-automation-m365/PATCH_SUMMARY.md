# Patch summary — 1.0.0.1 → candidate 1.1.0.0

## Existing flow preserved
`NF - Cadastro Inicial` keeps the same workflow GUID and SharePoint connection reference.

Changes:
- SharePoint site URL -> environment variable `cnf_SharePointSiteURL`.
- input document library GUID -> `cnf_DocumentLibraryId`.
- input folder -> `cnf_InputFolderPath`.
- control list GUID -> `cnf_ControlListId`.
- initial status -> `cnf_InitialStatus`.
- PDF suffix comparison is case-insensitive.
- invalid `Get items` filter `$filter: IDdoarquivo` replaced by an OData equality predicate against `{Identifier}`, escaping apostrophes.

## New cloud flow
`NF - Processamento Imediato` is added as an inactive workflow. It uses SharePoint's selected-file trigger, fetches file properties, accepts only PDFs, checks the same ID-based deduplication rule, gets the content, and creates the same initial SharePoint record when absent.

## Deliberately not added yet
- Invoice field extraction engine (licensing/accuracy not validated).
- Fiscal-field updates (real internal SharePoint column names not yet observed from an authoritative source).
- Desktop flow component (planned after the shared update contract is fixed).

These omissions are intentional gates, not forgotten work.
