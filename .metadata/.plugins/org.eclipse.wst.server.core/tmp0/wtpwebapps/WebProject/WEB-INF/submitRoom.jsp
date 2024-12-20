<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    String roomName = request.getParameter("room_name");
    String userName = request.getParameter("user_name");

    // 데이터베이스 연결
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String ownerId = null;

    try {
        // DB 연결 설정
       
        String url = "jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8";
        String dbUser = "root";
        String dbPassword = "1234";
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, dbUser, dbPassword);

        // 사용자 ID 찾기 (userName을 기준으로)
        String userSql = "SELECT id FROM users WHERE username = ?";
        pstmt = conn.prepareStatement(userSql);
        pstmt.setString(1, userName);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            ownerId = rs.getString("id");
        }

        // 방 생성
        if (ownerId != null) {
            String insertRoomSql = "INSERT INTO rooms (room_name, owner_id) VALUES (?, ?)";
            pstmt = conn.prepareStatement(insertRoomSql);
            pstmt.setString(1, roomName);
            pstmt.setString(2, ownerId);

            int rowsAffected = pstmt.executeUpdate();

            if (rowsAffected > 0) {
                out.println("<h2>방이 성공적으로 생성되었습니다!</h2>");
            } else {
                out.println("<h2>방 생성에 실패했습니다.</h2>");
            }
        } else {
            out.println("<h2>사용자 정보를 찾을 수 없습니다.</h2>");
        }

    } catch (Exception e) {
        out.println("<h2>오류 발생: " + e.getMessage() + "</h2>");
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

<p><a href="mainPage.jsp">메인 페이지로 돌아가기</a></p>
