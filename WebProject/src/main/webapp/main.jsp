<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.servlet.http.Cookie" %>

<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>메인 페이지</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f7fc;
            color: #000;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }

        .container {
            text-align: center;
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            width:700px;
            height:90%;
        }

        h1 {
            margin-bottom: 20px;
        }

        .form-container {
            margin-top: 20px;
        }

        input[type="text"] {
            padding: 10px;
            font-size: 16px;
            width: 200px;
            margin-right: 10px;
        }

        button {
            padding: 10px;
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
        }

        button:hover {
            background-color: #45a049;
        }

        .room-list {
            margin-top: 30px;
            overflow: auto;
            max-height:500px;
        }
		
		.room-list{
			-ms-overflow-style: none;
		}
		.room-list::-webkit-scrollbar{
			display:none;
		}

		
        .room-item {
            background-color: #f4f4f4;
            margin: 5px 0;
            padding: 10px;
            border-radius: 5px;
        }

    </style>
</head>
<body>

    <div class="container">
    <%
    Cookie[] cookies = request.getCookies();
    String userId = null;

    // 쿠키에서 사용자 ID 확인
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if (cookie.getName().equals("userId")) { // userId 쿠키를 사용
                userId = cookie.getValue();
                break;
            }
        }
    }

    if (userId != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            String url = "jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8";
            String dbUser = "root";
            String dbPassword = "1234";
            conn = DriverManager.getConnection(url, dbUser, dbPassword);

            // 현재 사용자 정보를 확인
            String sql = "SELECT room_id FROM users WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, userId);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                String roomId = rs.getString("room_id");
                if (roomId != null) {
                    // room_id가 있으면 해당 방 페이지로 리다이렉트
                    response.sendRedirect("roomPage.jsp?roomId=" + roomId);
                    return; // 추가 처리를 방지
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    } else {
        // 로그인하지 않은 경우
        response.sendRedirect("login.jsp");
        return;
    }
%>
        <%
            //Cookie[] cookies = request.getCookies();
            String userName = null;

            if (cookies != null) {
                for (Cookie cookie : cookies) {
                    if (cookie.getName().equals("userName")) {
                        userName = java.net.URLDecoder.decode(cookie.getValue(), "UTF-8");
                        break;
                    }
                }
            }

            if (userName != null) {
                out.println("<h1>" + userName + "님, 어서오세요!</h1>");
                out.println("<a href='logout.jsp'>로그아웃</a>");
                
        %>

        <!-- 방 생성 폼 -->
        <div class="form-container">
            <h2>새 방 만들기</h2>
            <form action="createRoom.jsp" method="post">
                <label for="roomName">방 이름:</label>
                <input type="text" id="roomName" name="roomName" required>
                <button type="submit">방 만들기</button>
            </form>
        </div>

        <!-- 방 목록 -->
        <div class="room-list">
            <h3>방 목록</h3>
            <%
                // 데이터베이스에서 방 목록 가져오기
                Connection conn = null;
                PreparedStatement pstmt = null;
                ResultSet rs = null;
                try {
                    String url = "jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8";
                    String dbUser = "root";
                    String dbPassword = "1234";
                    conn = DriverManager.getConnection(url, dbUser, dbPassword);

                    String sql = "SELECT room_id, room_name FROM rooms";
                    pstmt = conn.prepareStatement(sql);
                    rs = pstmt.executeQuery();

                    while (rs.next()) {
                        String roomId = rs.getString("room_id");
                        String roomName = rs.getString("room_name");
                        // 방 클릭 시 바로 입장하는 링크 생성
                        out.println("<div class='room-item'><a href='roomPage.jsp?roomId=" + roomId + "'>" + roomName + "</a></div>");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    out.println("<p>방 목록을 불러오는 데 실패했습니다.</p>");
                } finally {
                    try {
                        if (rs != null) rs.close();
                        if (pstmt != null) pstmt.close();
                        if (conn != null) conn.close();
                    } catch (SQLException e) {
                        e.printStackTrace();
                    }
                }
            %>
        </div>

        <%
            } else {
                response.sendRedirect("login.jsp");
            }
        %>
    </div>

</body>
</html>
