
--most active group member
SELECT
	name,
	COUNT(sent_message) mssg_count
FROM whatsapp_chats
JOIN group_members
ON whatsapp_chats.sender = group_members.phone_no
WHERE chat_status IN ('message', 'media')
GROUP BY 1
HAVING COUNT(sent_message) > 100
ORDER BY 2 DESC

--monthly top 3 most active group member
WITH mssg_count AS 	
(SELECT
 	EXTRACT('MONTH' FROM chat_timestamp) month_no,
	TO_CHAR(chat_timestamp, 'MONTH') AS month_name,
	name,
	COUNT(sent_message) AS tag_num,
 	RANK() OVER(PARTITION BY TO_CHAR(chat_timestamp, 'MONTH') ORDER BY COUNT(sent_message) DESC) AS tag_rank 
FROM whatsapp_chats
JOIN group_members
ON whatsapp_chats.sender = group_members.phone_no
WHERE chat_status IN ('message', 'media')
GROUP BY 1,2,3
ORDER BY 1,4 DESC)
SELECT *
FROM mssg_count
WHERE tag_rank < 4

--top 5 most mentioned members
SELECT 
	tagged,
	COUNT(tagged) tag_count
FROM whatsapp_chats
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

---monthly 3 most mentioned member 
WITH tag_count AS 	
(SELECT
 	EXTRACT('MONTH' FROM chat_timestamp) AS month_no,
	TO_CHAR(chat_timestamp, 'MONTH') AS month,
	name,
	COUNT(tagged) AS tag_num,
 	RANK() OVER(PARTITION BY TO_CHAR(chat_timestamp, 'MONTH') ORDER BY COUNT(tagged) DESC) AS tag_rank 
FROM whatsapp_chats
JOIN group_members
ON whatsapp_chats.sender = group_members.phone_no
WHERE tagged IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1,4 DESC)
SELECT *
FROM tag_count
WHERE tag_rank < 4

--monthly percent change
WITH monthly_mssg AS
(SELECT 
	DATE_TRUNC('MONTH', chat_timestamp) chat_month,
	COUNT(sent_message) curr,
 	LAG(COUNT(sent_message)) OVER(ORDER BY DATE_TRUNC('MONTH', chat_timestamp)) prev
FROM whatsapp_chats
WHERE chat_status IN ('message', 'media')
GROUP BY 1
ORDER BY 1)
SELECT 
	chat_month,
	curr,
	COALESCE(ROUND((curr/prev::DECIMAL)-1, 2)*100, 0) percent_change
FROM monthly_mssg

--daily message variation
SELECT
	EXTRACT(DOW FROM chat_timestamp),
	TO_CHAR(chat_timestamp, 'DAY'),
	COUNT(sent_message)
FROM whatsapp_chats
WHERE chat_status IN ('message', 'media')
GROUP BY 1,2
ORDER BY 1;
