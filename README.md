# TAE 2 - DBMS
## Luxury Automotive Dealership & Test Drive Management System

### Files
- `schema.sql` - MySQL 8.0 schema, keys, constraints and base indexes.
- `populate.py` - Generates `data.sql` with 150 rows for each TAE-1 table.
- `queries.sql` - Joins, subqueries, GROUP BY/HAVING, procedure, trigger, two views and EXPLAIN/indexing demos.
- `Presentation_Deck.pptx` - 10-minute presentation structure.
- `Presentation_Deck.pdf` - PDF version of the presentation.

### Run order
1. Open MySQL 8.0.
2. Execute `schema.sql`.
3. Keep `Nikhil_Mali_P28__Dataset.xlsx` in the same folder as `populate.py`.
4. Run:
   `python populate.py > data.sql`
5. Execute `data.sql` in MySQL.
6. Execute `queries.sql`.
7. For the live demo, show the DDL, a few records, complex queries, procedure, trigger, views and EXPLAIN before/after indexes.

### Important
This is Phase II of the same TAE-1 domain. The TAE-1 entities remain:
Customer, VIPMembership, Showroom, Manager, Vehicle, TestDrive, Feedback.
