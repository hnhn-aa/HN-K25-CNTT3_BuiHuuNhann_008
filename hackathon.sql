-- PHẦN 1: Tạo CSDL và các bảng Hệ thống Quản lý Bãi Xe Thông Minh
-- TẠO DATABASE

create database smartparkingsystem;
use smartparkingsystem;

-- TẠO CÁC BẢNG

-- Tạo bảng vị trí đỗ xe
create table parkingslots (
    slot_id varchar(5) primary key,
    floor int not null check (floor >= 1),
    slot_type varchar(20) not null,
    is_occupied boolean not null default 0,
    last_maintenance date
);

-- Tạo bảng thông tin xe
create table vehicles (
    vehicle_id varchar(10) primary key,
    vehicle_type varchar(20) not null,
    owner_name varchar(100),
    color varchar(20) not null
);

-- Tạo bảng thẻ gửi vé xe
create table tickets (
    ticket_id int primary key auto_increment,
    vehicle_id varchar(10) not null,
    ticket_type varchar(20) not null default 'daily',
    issue_date date not null,
    foreign key (vehicle_id) references vehicles(vehicle_id)
);

-- Tạo bảng nhật ký vào/ra
create table parkinglogs (
    log_id int primary key auto_increment,
    ticket_id int not null,
    slot_id varchar(5) not null,
    check_in_time datetime not null,
    check_out_time datetime,
    fee decimal(10,2),
    foreign key (ticket_id) references tickets(ticket_id),
    foreign key (slot_id) references parkingslots(slot_id)
);

-- THÊM DỮ LIỆU
insert into parkingslots (slot_id, floor, slot_type, is_occupied) 
values	('s01', 1, 'car', 1), 
		('s02', 1, 'car', 0), 
        ('s03', 2, 'motorbike', 1),
        ('s04', 2, 'motorbike', 1), 
        ('s05', 1, 'car', 0);

insert into vehicles 
values	('29a-12345', 'car', 'nguyễn văn an', 'black'), 
		('30h-67890', 'car', 'trần thị bình', 'white'),
		('29f-11122', 'motorbike', 'lê văn cường', 'blue'), 
        ('29k-55566', 'motorbike', 'phạm minh dũng', 'red');

insert into tickets (ticket_id, vehicle_id, ticket_type, issue_date) 
values	(1, '29a-12345', 'monthly', '2025-01-01'), 
		(2, '30h-67890', 'daily', '2025-11-10'),
        (3, '29f-11122', 'daily', '2025-11-10'), 
        (4, '29k-55566', 'monthly', '2025-02-15');

insert into parkinglogs (log_id, ticket_id, slot_id, check_in_time, check_out_time, fee) 
values	(1, 1, 's01', '2025-11-10 08:00:00', '2025-11-10 12:00:00', 40000.00),
		(2, 2, 's02', '2025-11-10 09:00:00', null, null),
		(3, 3, 's03', '2025-11-10 10:00:00', '2025-11-10 18:00:00', 16000.00),
		(4, 4, 's04', '2025-11-11 07:00:00', null, null);

set sql_safe_updates = 0;

-- 4. Xe tại log_id = 2 đã ra vào lúc '2025-11-10 15:00:00', tính phí 60,000 và cập nhật check_out_time, fee.
update parkinglogs 
set check_out_time = '2025-11-10 15:00:00', fee = 60000
where log_id = 2;

-- 5. Cập nhật is_occupied = 0 cho vị trí S01 vì xe đã rời bãi.
update parkingslots 
set is_occupied = 0 
where slot_id = 's01';

-- 6. Xóa tất cả các thông tin xe (Vehicles) không có thẻ gửi xe (Tickets) nào.
delete from vehicles 
where vehicle_id not in (
	select vehicle_id 
    from tickets
);

-- PHẦN 2: Truy vấn dữ liệu cơ bản 

-- 10. Liệt kê tất cả các vị trí đỗ xe còn trống (is_occupied = 0) ở tầng 1.
select * 
from parkingslots 
where is_occupied = 0 
and floor = 1;

-- 11. Lấy biển số xe và loại xe của tất cả các xe là 'Motorbike'.
select vehicle_id, vehicle_type 
from vehicles 
where vehicle_type = 'motorbike';

-- 12. Hiển thị danh sách nhật ký vào/ra gồm log_id, check_in_time, sắp xếp theo check_in_time mới nhất.
select log_id, check_in_time 
from parkinglogs 
order by check_in_time desc;

-- 13. Lấy ra 3 vị trí đỗ xe có số tầng (floor) cao nhất.
select * 
from parkingslots 
order by floor desc 
limit 3;

-- 14. Hiển thị thông tin xe (biển số, màu sắc), bỏ qua xe đầu tiên và lấy 2 xe tiếp theo.
select * 
from vehicles 
limit 2 offset 1;

-- 15. Cập nhật fee bằng 0 cho tất cả các xe có ticket_type là 'Monthly' (xe tháng không thu phí lượt).
update parkinglogs p 
join tickets t 
on p.ticket_id = t.ticket_id 
set p.fee = 0 
where t.ticket_type = 'monthly';

-- 16. Chuyển đổi toàn bộ owner_name của khách hàng thành chữ in hoa.
update vehicles 
set owner_name = upper(owner_name);

-- 17. Xóa các vị trí đỗ xe loại 'Motorbike' ở tầng 1 (nếu có) và xử lý ràng buộc khóa ngoại.
delete from parkinglogs 
where slot_id 
in (
	select slot_id 
    from parkingslots 
    where slot_type = 'motorbike' and floor = 1
);

delete from parkingslots 
where slot_type = 'motorbike' and floor = 1;

-- PHẦN 3: Truy vấn dữ liệu nâng cao

-- 18. Hiển thị log_id, vehicle_id, slot_id, check_in_time của những xe đang ở trong bãi (check_out_time IS NULL).
select log_id, vehicle_id, slot_id, check_in_time 
from parkinglogs p
join tickets t 
on p.ticket_id = t.ticket_id 
where check_out_time is null;

-- 19. Liệt kê toàn bộ vị trí đỗ (slot_id) và số lần vị trí đó đã được sử dụng để đỗ xe. Hiển thị cả những vị trí chưa từng được sử dụng.
select s.slot_id, count(l.log_id) as total_uses 
from parkingslots s 
left join parkinglogs l 
on s.slot_id = l.slot_id 
group by s.slot_id;

-- 20. Tính tổng doanh thu (fee) thu được theo từng loại xe ('Car' vs 'Motorbike').
select v.vehicle_type, sum(l.fee) as total_revenue 
from parkinglogs l 
join tickets t 
on l.ticket_id = t.ticket_id 
join vehicles v 
on t.vehicle_id = v.vehicle_id 
group by v.vehicle_type;

-- 21. Thống kê số lượng lượt gửi xe của từng thẻ (ticket_id). Chỉ hiển thị những thẻ đã gửi từ 2 lần trở lên.
select ticket_id, count(*) as visit_count 
from parkinglogs 
group by ticket_id 
having visit_count >= 2;

-- 22. Tìm các lượt gửi xe có phí (fee) cao hơn mức phí trung bình của tất cả các lượt gửi đã thanh toán.
select * 
from parkinglogs 
where fee > (
	select avg(fee) 
    from parkinglogs 
    where fee is not null
);

-- 23. Hiển thị biển số xe (vehicle_id) và tên chủ xe đã từng đỗ tại vị trí "S03".
select distinct v.vehicle_id, v.owner_name 
from vehicles v 
join tickets t 
on v.vehicle_id = t.vehicle_id 
join parkinglogs l 
on t.ticket_id = l.ticket_id 
where l.slot_id = 's03';

-- 24. Liệt kê các xe đã gửi trong bãi quá 8 tiếng (Dựa trên check_out_time và check_in_time).
select * 
from parkinglogs 
where timestampdiff(hour, check_in_time, check_out_time) > 8;

-- 25. Tính tổng phí gửi xe dựa trên quy tắc: Nếu là xe 'Car' thì 10,000/giờ, xe 'Motorbike' thì 2,000/giờ. (Tiền = Số giờ * Đơn giá).
select log_id, 
       timestampdiff(hour, check_in_time, check_out_time) * (
			case 
				when v.vehicle_type = 'car' then 10000 else 2000 
				end
		) as calculated_fee
from parkinglogs l 
join tickets t 
on l.ticket_id = t.ticket_id 
join vehicles v 
on t.vehicle_id = v.vehicle_id;