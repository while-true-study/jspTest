<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.servlet.http.Cookie" %>
<%@ page import="java.text.DecimalFormat" %>
<!DOCTYPE html>

<head>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<div class="container">
    <%
request.setCharacterEncoding("UTF-8");
    String roomId = request.getParameter("roomId");
    if (roomId == null) {
        response.sendRedirect("main.jsp"); // 방 ID가 없으면 메인 페이지로 이동
        return;
    }

    // 사용자 정보를 쿠키에서 가져오기
    Cookie[] cookies = request.getCookies();
    String userId = null; // 사용자 ID
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if (cookie.getName().equals("userId")) {
                userId = cookie.getValue();
                break;
            }
        }
    }

    String message = null; // 메시지 저장 변수

    if (userId != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            String url = "jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8";
            String dbUser = "root";
            String dbPassword = "1234";
            conn = DriverManager.getConnection(url, dbUser, dbPassword);

            // 1. 방 이름 가져오기
            String roomName = null;
            String getRoomNameSql = "SELECT room_name FROM rooms WHERE room_id = ?";
            pstmt = conn.prepareStatement(getRoomNameSql);
            pstmt.setString(1, roomId);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                roomName = rs.getString("room_name");
                out.println("<h1>" + roomName  + " 입장 완료</h1>");
            } else {
                out.println("<p>존재하지 않는 방입니다.</p>");
                return; // 방이 없으면 나머지 로직 실행 중단
            }

            // 2. 사용자 방 정보 업데이트
            String sql = "UPDATE users SET room_id = ? WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, roomId);  // 현재 방 ID
            pstmt.setString(2, userId);  // 로그인한 사용자 ID
            pstmt.executeUpdate();

            pstmt.close(); // PreparedStatement 닫기

            // 3. 참여 인원 목록 가져오기
            String getUsersSql = "SELECT name FROM users WHERE room_id = ?";
            pstmt = conn.prepareStatement(getUsersSql);
            pstmt.setString(1, roomId);
            rs = pstmt.executeQuery();
            
            out.println("<h2>참여 인원</h2>");
            
            out.println("<ul>");
            boolean hasUsers = false;

            while (rs.next()) {
                String userName = rs.getString("name");
                out.println("<li>" + userName + "</li>");
                hasUsers = true;
            }

            if (!hasUsers) {
                out.println("<p>현재 이 방에 참여한 인원이 없습니다.</p>");
            }

            out.println("</ul>");

            // 4. 물품 목록 및 금액 합산
            String getPurchasesSql = "SELECT item_name, item_cost, purchases_id FROM purchases WHERE room_id = ?";
            pstmt = conn.prepareStatement(getPurchasesSql);
            pstmt.setString(1, roomId);
            rs = pstmt.executeQuery();

            double totalCost = 0;
            int itemCount = 0;

            out.println("<h2>물품 목록</h2>");
            out.println("<table>");
            out.println("<thead><tr><th>물품 이름</th><th>물품 가격</th><th>삭제</th></tr></thead>");
            out.println("<tbody>");
            while (rs.next()) {
                String itemName = rs.getString("item_name");
                double itemCost = rs.getDouble("item_cost");
                int purchasesId = rs.getInt("purchases_id");
                totalCost += itemCost;
                itemCount++;
                // out.println("<tr><td>" + itemName + "</td><td>" + itemCost + " 원</td><td><button>V</button></td><td><button>X</button></td></tr>");
                out.println("<tr><td>" + itemName + "</td><td>" + itemCost + " 원</td>");
                out.println("<td><form action='roomPage.jsp?roomId=" + roomId + "' method='post'>"
                            + "<input type='hidden' name='action' value='cancel'>"
                            + "<input type='hidden' name='purchasesId' value='" + purchasesId + "'>"
                            + "<button type='submit'>X</button></form></td></tr>");
            }
            out.println("</tbody>");
            out.println("</table>");

            // 5. 참여 인원 수와 인당 금액 계산
            String getUsersCountSql = "SELECT COUNT(*) AS user_count FROM users WHERE room_id = ?";
            pstmt = conn.prepareStatement(getUsersCountSql);
            pstmt.setString(1, roomId);
            rs = pstmt.executeQuery();
            int userCount = 0;
            if (rs.next()) {
                userCount = rs.getInt("user_count");
            }

            if (userCount > 0) {
                double amountPerUser = totalCost / userCount;
                DecimalFormat df = new DecimalFormat("#,###.#");  // 천 단위 구분자 추가, 소수점 첫째자리까지
                String formattedAmount = df.format(amountPerUser);
                out.println("<h3>총 물품 금액: " + totalCost + "원</h3>");
                out.println("<h3>참여 인원: " + userCount + "명</h3>");
                out.println("<h3>각 인당 내야 할 금액: " + formattedAmount + " 원</h3>");
            } else {
                out.println("<p>참여 인원이 없습니다.</p>");
            }

            rs.close(); // ResultSet 닫기
            pstmt.close(); // PreparedStatement 닫기
        } catch (SQLException e) {
            e.printStackTrace();
            out.println("<p>SQL 오류 발생: " + e.getMessage() + "</p>");
        } catch (Exception e) {
            out.println("<p>오류 발생: " + e.getMessage() + "</p>");
        }

        // 물품 추가 처리 (POST 요청 처리)
        if (request.getMethod().equalsIgnoreCase("POST")) {
            request.setCharacterEncoding("UTF-8");
            String action = request.getParameter("action");
            String purchasesId = request.getParameter("purchasesId");
            String itemName = request.getParameter("item_name");
            String itemCost = request.getParameter("item_cost");
            if ("approve".equals(action) && purchasesId != null) {
                try {
                    conn = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8", "root", "1234");
					
                    // 물품 승인 처리: approved 값 1로 변경
                    String approveSql = "UPDATE purchases SET approved = 1 WHERE purchases_id = ?";
                    pstmt = conn.prepareStatement(approveSql);
                    pstmt.setString(1, purchasesId);
                    pstmt.executeUpdate();
                    
                    message = "물품이 승인되었습니다.";
                    pstmt.close();
                    conn.close();
                    response.sendRedirect("roomPage.jsp?roomId=" + roomId);
                    return;
                } catch (SQLException e) {
                    message = "SQL 오류 발생: " + e.getMessage();
                }
            } else if ("cancel".equals(action) && purchasesId != null) {
                try {
                    conn = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8", "root", "1234");

                    // 물품 취소 처리: 해당 물품을 삭제
                    String cancelSql = "DELETE FROM purchases WHERE purchases_id = ?";
                    pstmt = conn.prepareStatement(cancelSql);
                    pstmt.setString(1, purchasesId);
                    pstmt.executeUpdate();
                    
                    message = "물품이 취소되었습니다.";
                    pstmt.close();
                    conn.close();
                    response.sendRedirect("roomPage.jsp?roomId=" + roomId);
                    return;
                } catch (SQLException e) {
                    message = "SQL 오류 발생: " + e.getMessage();
                }
            }
            if (itemName != null && !itemName.isEmpty() && itemCost != null && !itemCost.isEmpty()) {
                try {
                    double cost = Double.parseDouble(itemCost); // 숫자로 변환
                    conn = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8", "root", "1234");

                    // 구매 정보를 삽입하는 SQL 쿼리
                    String sql2 = "INSERT INTO purchases (room_id, item_name, item_cost) VALUES (?, ?, ?)";
                    pstmt = conn.prepareStatement(sql2);
                    pstmt.setString(1, roomId); // room_id를 실제 방 ID로 설정
                    pstmt.setString(2, itemName); // item_name
                    pstmt.setDouble(3, cost); // item_cost

                    // 쿼리 실행
                    int rowsAffected = pstmt.executeUpdate();

                    // 결과 메시지 설정
                    if (rowsAffected > 0) {
                        message = "물품이 추가되었습니다!";
                        // 물품을 추가한 후, 페이지를 리다이렉트합니다.
                        response.sendRedirect("roomPage.jsp?roomId=" + roomId);
                        return; // 여기서 더 이상 코드를 실행하지 않도록 합니다.
                    } else {
                        message = "물품 추가에 실패했습니다.";
                    }

                    pstmt.close();
                    conn.close();
                } catch (NumberFormatException e) {
                    message = "물품 가격은 숫자여야 합니다.";
                } catch (SQLException e) {
                    message = "SQL 오류 발생: " + e.getMessage();
                    e.printStackTrace();
                } catch (Exception e) {
                    message = "물품 추가 중 오류 발생: " + e.getMessage();
                    e.printStackTrace();
                }
            } else {
                message = "모든 필드를 채워주세요.";
            }
        }
    } else {
        response.sendRedirect("login.jsp"); // 사용자 ID가 없으면 로그인 페이지로 이동
    }
%>

    <!-- 결과 메시지 출력 -->
    <% if (message != null) { %>
    <p><%= message %></p>
    <% } %>

    <!-- 물품 추가 폼 -->
    <h2>물품 추가</h2>
    <div class="buttons">
        <form action="roomPage.jsp?roomId=<%= roomId %>" method="post">
            <div>
                <label for="item_name">물품 이름</label>
                <input type="text" id="item_name" name="item_name" class="inputbox" required>
            </div>
            <div>
                <label for="item_cost">물품 가격</label>
                <input type="number" id="item_cost" name="item_cost" class="inputbox" required>
            </div>
            <button type="submit">물품 추가</button>
        </form>

        <!-- 방 나가기 폼 -->
    </div>
    <div class="footer-button">
	        <form action="leaveRoom.jsp" method="post">
	            <input type="hidden" name="roomId" value="<%= roomId %>">
	            <button type="submit" class="leave-room-button">방 나가기</button>
	        </form>
	        <a href='logout.jsp'><button type="submit" class="leave-room-button">로그아웃</button></a>
       </div>
</div>