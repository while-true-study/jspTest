<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.Connection, java.sql.DriverManager, java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %> <!-- BCrypt 라이브러리 추가 -->
<%@ page import="javax.servlet.http.Cookie" %>

<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>로그인</title>
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

        .login-container {
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
            text-align: center;
        }

        h1 {
            color: #333;
            margin-bottom: 20px;
        }

        .form-group {
            margin: 15px 0;
            text-align: left;
        }

        .form-group label {
            display: block;
            color: #333;
            font-size: 14px;
        }

        .form-group input {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 16px;
            margin-top: 5px;
            box-sizing: border-box;
        }

        button {
            width: 100%;
            padding: 12px;
            background-color: #4CAF50;
            color: white;
            border: none;
            font-size: 16px;
            border-radius: 4px;
            cursor: pointer;
            margin-top: 20px;
            transition: background-color 0.3s;
            box-sizing: border-box;
        }

        button:hover {
            background-color: #45a049;
        }

        .footer {
            margin-top: 20px;
            font-size: 14px;
        }

        .footer a {
            color: #4CAF50;
            text-decoration: none;
        }

        .error-message {
            color: red;
            margin-top: 15px;
        }
    </style>
</head>
<body>

    <div class="login-container">
        <h1>로그인</h1>
        <form action="login.jsp" method="post">
            <div class="form-group">
                <label for="email">이메일</label>
                <input type="email" id="email" name="email" required>
            </div>
            <div class="form-group">
                <label for="password">비밀번호</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit">로그인</button>
        </form>

        <div class="footer">
            <p>계정이 없으신가요? <a href="register.jsp">회원가입</a></p>
        </div>

        <%
            if (request.getMethod().equalsIgnoreCase("POST")) {
                String email = request.getParameter("email");
                String password = request.getParameter("password");

                String connString = "jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8";
                String dbUser = "root";
                String dbPassword = "1234";

                try {
                    Class.forName("org.mariadb.jdbc.Driver");
                    Connection conn = DriverManager.getConnection(connString, dbUser, dbPassword);

                    // 비밀번호와 userId를 포함하여 사용자 정보 조회
                    String sql = "SELECT id, name, password FROM users WHERE email = ?";
                    PreparedStatement pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, email);

                    ResultSet rs = pstmt.executeQuery();

                    if (rs.next()) {
                        String userId = rs.getString("id"); // 사용자 ID 가져오기
                        String userName = rs.getString("name"); // 사용자 이름 가져오기
                        String hashedPassword = rs.getString("password"); // 암호화된 비밀번호

                        // 입력한 비밀번호와 해시된 비밀번호 비교
                        if (BCrypt.checkpw(password, hashedPassword)) {
                            // 로그인 성공 시 userId와 userName 쿠키로 저장
                            Cookie userNameCookie = new Cookie("userName", java.net.URLEncoder.encode(userName, "UTF-8"));
                            Cookie userIdCookie = new Cookie("userId", userId);  // userId 쿠키 저장
                            userNameCookie.setMaxAge(60 * 60 * 24); // 1일 동안 유효
                            userIdCookie.setMaxAge(60 * 60 * 24); // 1일 동안 유효
                            response.addCookie(userNameCookie);
                            response.addCookie(userIdCookie);

                            // 로그인 후 사용자의 room_id 체크
                            String roomCheckSql = "SELECT room_id FROM users WHERE id = ?";
                            PreparedStatement roomCheckStmt = conn.prepareStatement(roomCheckSql);
                            roomCheckStmt.setString(1, userId);
                            ResultSet roomCheckRs = roomCheckStmt.executeQuery();

                            if (roomCheckRs.next() && roomCheckRs.getString("room_id") != null) {
                                // 사용자가 방에 가입되어 있으면 해당 방으로 리다이렉트
                                String roomId = roomCheckRs.getString("room_id");
                                response.sendRedirect("roomPage.jsp?roomId=" + roomId);
                            } else {
                                // 방에 가입되지 않은 경우 메인 페이지로 리다이렉트
                                response.sendRedirect("main.jsp");
                            }
                        } else {
                            out.println("<p class='error-message'>이메일 또는 비밀번호가 잘못되었습니다.</p>");
                        }
                    } else {
                        out.println("<p class='error-message'>이메일 또는 비밀번호가 잘못되었습니다.</p>");
                    }

                    rs.close();
                    pstmt.close();
                    conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                    out.println("<p class='error-message'>로그인 실패: " + e.getMessage() + "</p>");
                }
            }
        %>
    </div>

</body>
</html>
