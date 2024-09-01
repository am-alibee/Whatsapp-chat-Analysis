
--create table of drop if it already exits
DROP TABLE IF EXISTS whatsapp_chats;
CREATE TABLE whatsapp_chats 
(
	chat TEXT,
	chat_timestamp TIMESTAMP,
	chat_status TEXT,
	sender TEXT,
	sent_message TEXT,
	tagged Text
);

--add meta data to the table and columns
COMMENT ON TABLE whatsapp_chats IS 'This table holds the data of the EPS thursday whatsapp group chat';
COMMENT ON COLUMN whatsapp_chats.chat IS 'Stores the chat data';
COMMENT ON COLUMN whatsapp_chats.chat_timestamp IS 'timestamp of the chat';
COMMENT ON COLUMN whatsapp_chats.chat_status IS 'Describe whether the message is a message or a notification';
COMMENT ON COLUMN whatsapp_chats.sender IS 'sender of the message';
COMMENT ON COLUMN whatsapp_chats.sent_message IS 'message sent by the sender';
COMMENT ON COLUMN whatsapp_chats.tagged IS 'first member tagged in a message';

--extract and load data into the table
COPY whatsapp_chats (chat)
FROM 'C:\Users\USER\Documents\DATA ANALYSIS\portfolio\whatsapp\WhatsApp Chat with EPS Thursday SG 1.txt'
WITH (FORMAT CSV);

--create a backup table before transforming the chats table
DROP TABLE IF EXISTS whatsapp_chats__backup;
CREATE TABLE whatsapp_chats__backup AS
SELECT *
FROM whatsapp_chats;

--compare the no of rows in both table
SELECT count(*)
FROM whatsapp_chats__backup;
SELECT count(*)
FROM whatsapp_chats;

--remove all uneccessay data
DELETE FROM whatsapp_chats
WHERE chat NOT LIKE '__/__/____%'
OR chat LIKE '%Messages and calls are end-to-end encrypted%'
OR chat LIKE 'FC/23%'
OR chat LIKE '%Your security code with%'
OR chat LIKE '%pinned a message%'
OR chat LIKE '% Only messages that mention @Meta AI are sent to Meta%'
OR chat LIKE '%changed their phone%'
OR chat LIKE '%changed this group%'
OR chat LIKE '%changed to +%'
OR chat LIKE '%changed the settings so%';



SELECT *
FROM whatsapp_chats

--create a timestamp column for the chats
UPDATE whatsapp_chats
SET chat_timestamp = TO_TIMESTAMP(SPLIT_PART(chat, ' -', 1), 'DD/MM/YYYY HH12:MIAMPM');

SELECT SPLIT_PART(chat, ' - ', 2)
FROM whatsapp_chats

--update chat column with the part excluding the timestamp
UPDATE whatsapp_chats
SET chat = SPLIT_PART(chat, ' - ', 2)

--find the removed and added notifications
SELECT *
FROM whatsapp_chats
WHERE 
	chat NOT LIKE '+2%' 
	AND (chat LIKE '%added%' OR chat LIKE '%removed +%');

--set the status to removed for the removed notification
UPDATE whatsapp_chats
SET chat_status = 'Removed'
WHERE 
	chat NOT LIKE '+2%' 
	AND chat LIKE '%removed +%';
	
--set the status to added for the added notification	
UPDATE whatsapp_chats
SET chat_status = 'Added'
WHERE 
	chat NOT LIKE '+2%' 
	AND chat LIKE '%added%';
	
--set chat to null for update and removed notifications
UPDATE whatsapp_chats
SET chat = NULL
WHERE 
	chat NOT LIKE '+2%' 
	AND (chat LIKE '%added%' OR chat LIKE '%removed +%');

--find pattern of the join notification
SELECT chat
FROM whatsapp_chats
WHERE chat LIKE '+2%joined using %';

--update the chat status for the joined notification using the pattern
UPDATE whatsapp_chats
SET chat_status = 'Joined'
WHERE chat LIKE '+2%joined using %' OR chat LIKE '% joined using this group%';

--set the chat to null fot the join notifications
UPDATE whatsapp_chats
SET chat = NULL
WHERE chat LIKE '+2%joined using %' OR chat LIKE '% joined using this group%';

--find the pattern for left notificaton
SELECT chat
FROM whatsapp_chats
WHERE chat LIKE '+2%left'

--update the chat status for the left notification using the pattern
UPDATE whatsapp_chats
SET chat_status = 'Left'
WHERE chat LIKE '+2%left';

--set the chat to null fot the left notifications
UPDATE whatsapp_chats
SET chat = NULL
WHERE chat LIKE '+2%left';


SELECT *
FROM whatsapp_chats
ORDER BY 3 DESC;

SELECT DISTINCT TRIM(SPLIT_PART(chat, ':', 1))
FROM whatsapp_chats
ORDER BY 1 DESC;

--removed another whatsapp notification which was not identified earlier
DELETE FROM whatsapp_chats
WHERE chat LIKE '% turned on admin approval to join this group.%';

SELECT *
FROM whatsapp_chats
ORDER BY 3 DESC;

--updated the sender column with their details
UPDATE whatsapp_chats
SET sender = TRIM(SPLIT_PART(chat, ':', 1));

SELECT DISTINCT sender
FROM whatsapp_chats
ORDER BY 1 DESC;

SELECT DISTINCT REPLACE(sender, ' ', '')
FROM whatsapp_chats
WHERE sender LIKE '+2%'
ORDER BY 1 DESC;

--removed the space from senders phone number
UPDATE whatsapp_chats
SET sender = REPLACE(sender, ' ', '')
WHERE sender LIKE '+2%';



SELECT SPLIT_PART(chat, ': ', 2)
FROM whatsapp_chats;

--removed the sender details from the chat column
UPDATE whatsapp_chats
SET chat = SPLIT_PART(chat, ': ', 2);

SELECT *
FROM whatsapp_chats;

--update sent_message column with chat colum
UPDATE whatsapp_chats
SET sent_message = chat;

--drop the chat column
ALTER TABLE whatsapp_chats
DROP COLUMN chat;

--update status for chat containing media doc
UPDATE whatsapp_chats
SET 
	chat_status = 'media'
WHERE sent_message LIKE '<Media omitted>%';

SELECT *
FROM whatsapp_chats
WHERE chat_status IS NULL;

--update the chat_status for the messages
UPDATE whatsapp_chats
SET 
	chat_status = 'message'
WHERE chat_status IS NULL;

--find chats without a chat_status
SELECT *
FROM whatsapp_chats
WHERE chat_status IS NULL;

SELECT  
	DISTINCT REPLACE(CONCAT('+' ,SUBSTRING(sent_message, POSITION('@' IN sent_message)+1, 13)), '@', '')
FROM public.whatsapp_chats
WHERE
	sent_message NOT LIKE '%@1313%'
	AND sent_message LIKE '%@2%'
	AND sent_message LIKE '%911305113%';
	
--update tagged column with the member tagged
UPDATE whatsapp_chats
SET tagged = REPLACE(CONCAT('+' ,SUBSTRING(sent_message, POSITION('@' IN sent_message)+1, 13)), '@', '')
WHERE
	sent_message NOT LIKE '%@1313%'
	AND sent_message LIKE '%@2%';
	
--create group member
CREATE TABLE group_members
(
	phone_no CHAR(14) PRIMARY KEY,
	name TEXT
);

